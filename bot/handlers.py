import logging
from datetime import datetime

from telegram import KeyboardButton, ReplyKeyboardMarkup, ReplyKeyboardRemove, Update
from telegram.ext import (
    CommandHandler,
    ContextTypes,
    ConversationHandler,
    MessageHandler,
    filters,
)

import database as db
import gis

log = logging.getLogger(__name__)

# ── Conversation states ────────────────────────────────────────────────────────
WORK_ADDRESS, HOME_ADDRESS = range(2)

# Stored in context.user_data to know what we're updating
_MODE_FULL = "full"      # /start  — collect work then home
_MODE_WORK = "work"      # /setwork — collect work only
_MODE_HOME = "home"      # /sethome — collect home only


# ── Helpers ────────────────────────────────────────────────────────────────────

def _location_kb() -> ReplyKeyboardMarkup:
    return ReplyKeyboardMarkup(
        [[KeyboardButton("📍 Отправить геолокацию", request_location=True)]],
        resize_keyboard=True,
        one_time_keyboard=True,
    )


def _format_routes(routes: list[dict], header: str) -> str:
    lines = [header, ""]
    for r in routes:
        names = " → ".join(f"№{n}" for n in r["route_names"])
        mins = r["arrival_minutes"]
        if mins is None:
            when = "время неизвестно"
        elif mins == 0:
            when = "уже на остановке!"
        elif mins == 1:
            when = "через 1 минуту"
        else:
            when = f"через {mins} мин"
        stop = f"  (ост. {r['first_stop']})" if r["first_stop"] else ""
        lines.append(f"• {names} — {when}{stop}  |  в пути ~{r['total_time']} мин")

    known = [r for r in routes if r["arrival_minutes"] is not None]
    if known:
        best = min(known, key=lambda r: r["arrival_minutes"])
        if best["arrival_minutes"] <= 3:
            lines.append("\n⚡ Выходи прямо сейчас!")
    return "\n".join(lines)


async def _resolve_location(update: Update) -> tuple[float, float, str] | None:
    """
    Returns (lat, lon, address_label) from either a Telegram location
    or a text address string. Returns None if geocoding fails.
    """
    if update.message.location:
        lat = update.message.location.latitude
        lon = update.message.location.longitude
        label = f"{lat:.5f}, {lon:.5f}"
        return lat, lon, label

    text = update.message.text.strip()
    coords = await gis.geocode(text)
    if not coords:
        return None
    lat, lon = coords
    return lat, lon, text


# ── /start ─────────────────────────────────────────────────────────────────────

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data["mode"] = _MODE_FULL
    await update.message.reply_text(
        "👋 Привет! Я помогу тебе ориентироваться в транспорте Алматы.\n\n"
        "Укажи адрес *работы* — текстом или геолокацией.",
        reply_markup=_location_kb(),
        parse_mode="Markdown",
    )
    return WORK_ADDRESS


# ── /setwork ───────────────────────────────────────────────────────────────────

async def setwork_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data["mode"] = _MODE_WORK
    await update.message.reply_text(
        "Укажи новый адрес *работы* — текстом или геолокацией.",
        reply_markup=_location_kb(),
        parse_mode="Markdown",
    )
    return WORK_ADDRESS


# ── /sethome ───────────────────────────────────────────────────────────────────

async def sethome_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    context.user_data["mode"] = _MODE_HOME
    await update.message.reply_text(
        "Укажи новый *домашний* адрес — текстом или геолокацией.",
        reply_markup=_location_kb(),
        parse_mode="Markdown",
    )
    return HOME_ADDRESS


# ── Receiving addresses ────────────────────────────────────────────────────────

async def receive_work_address(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    resolved = await _resolve_location(update)
    if not resolved:
        await update.message.reply_text(
            "❌ Не могу найти этот адрес. Попробуй другую формулировку или отправь геолокацию.",
            reply_markup=_location_kb(),
        )
        return WORK_ADDRESS

    lat, lon, label = resolved
    context.user_data["work"] = {"lat": lat, "lon": lon, "address": label}

    mode = context.user_data.get("mode", _MODE_FULL)

    if mode == _MODE_WORK:
        await db.save_user(
            update.effective_user.id,
            work_lat=lat, work_lon=lon, work_address=label,
        )
        await update.message.reply_text(
            f"✅ Адрес работы обновлён:\n{label}",
            reply_markup=ReplyKeyboardRemove(),
        )
        return ConversationHandler.END

    # Full setup — ask for home next
    await update.message.reply_text(
        f"✅ Работа: {label}\n\nТеперь укажи *домашний* адрес.",
        reply_markup=_location_kb(),
        parse_mode="Markdown",
    )
    return HOME_ADDRESS


async def receive_home_address(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    resolved = await _resolve_location(update)
    if not resolved:
        await update.message.reply_text(
            "❌ Не могу найти этот адрес. Попробуй другую формулировку или отправь геолокацию.",
            reply_markup=_location_kb(),
        )
        return HOME_ADDRESS

    lat, lon, label = resolved
    user_id = update.effective_user.id
    mode = context.user_data.get("mode", _MODE_FULL)

    if mode == _MODE_HOME:
        await db.save_user(user_id, home_lat=lat, home_lon=lon, home_address=label)
        await update.message.reply_text(
            f"✅ Домашний адрес обновлён:\n{label}",
            reply_markup=ReplyKeyboardRemove(),
        )
        return ConversationHandler.END

    # Full setup — save both work and home
    work = context.user_data["work"]
    await db.save_user(
        user_id,
        work_lat=work["lat"], work_lon=work["lon"], work_address=work["address"],
        home_lat=lat, home_lon=lon, home_address=label,
    )
    await update.message.reply_text(
        f"✅ Домашний адрес: {label}\n\n"
        "Всё готово! Доступные команды:\n"
        "/route — маршруты от работы до дома\n"
        "/leaving — ближайший автобус прямо сейчас\n"
        "/schedule 18:30 — авто-уведомление по времени\n"
        "/setwork — изменить адрес работы\n"
        "/sethome — изменить домашний адрес",
        reply_markup=ReplyKeyboardRemove(),
    )
    return ConversationHandler.END


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    await update.message.reply_text("Отменено.", reply_markup=ReplyKeyboardRemove())
    return ConversationHandler.END


# ── /route ─────────────────────────────────────────────────────────────────────

async def route_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user = await db.get_user(update.effective_user.id)
    if not user or user["work_lat"] is None or user["home_lat"] is None:
        await update.message.reply_text("⚠️ Сначала настрой адреса через /start")
        return

    msg = await update.message.reply_text("🔍 Ищу маршруты…")
    routes = await gis.get_transit_routes(
        user["work_lat"], user["work_lon"],
        user["home_lat"], user["home_lon"],
    )

    if not routes:
        await msg.edit_text("❌ Маршруты не найдены. Проверь адреса через /setwork и /sethome.")
        return

    text = "🚌 *Маршруты от работы до дома:*\n\n"
    for i, r in enumerate(routes, 1):
        names = " → ".join(f"№{n}" for n in r["route_names"])
        tr = f", {r['transfers']} пересадка" if r["transfers"] == 1 else (f", {r['transfers']} пересадки" if r["transfers"] > 1 else "")
        text += f"{i}. {names} — ~{r['total_time']} мин{tr}\n"

    await msg.edit_text(text, parse_mode="Markdown")


# ── /leaving ───────────────────────────────────────────────────────────────────

async def leaving_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user = await db.get_user(update.effective_user.id)
    if not user or user["work_lat"] is None or user["home_lat"] is None:
        await update.message.reply_text("⚠️ Сначала настрой адреса через /start")
        return

    msg = await update.message.reply_text("🔍 Проверяю ближайшие автобусы…")
    routes = await gis.get_transit_routes(
        user["work_lat"], user["work_lon"],
        user["home_lat"], user["home_lon"],
        departure_time=datetime.now(),
    )

    if not routes:
        await msg.edit_text("❌ Маршруты не найдены.")
        return

    text = _format_routes(routes, "🚌 *Ближайшие автобусы от работы:*")
    await msg.edit_text(text, parse_mode="Markdown")


# ── /schedule ──────────────────────────────────────────────────────────────────

async def schedule_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id = update.effective_user.id
    args = context.args or []

    if not args:
        await update.message.reply_text(
            "Использование:\n"
            "/schedule 18:30 — уведомление каждый день в 18:30\n"
            "/schedule off — отключить"
        )
        return

    if args[0].lower() == "off":
        await db.save_user(user_id, auto_notify_time=None)
        _remove_jobs(context, user_id)
        await update.message.reply_text("✅ Авто-уведомление отключено.")
        return

    time_str = args[0]
    try:
        hour, minute = map(int, time_str.split(":"))
        assert 0 <= hour <= 23 and 0 <= minute <= 59
    except (ValueError, AssertionError):
        await update.message.reply_text("❌ Неверный формат. Пример: /schedule 18:30")
        return

    await db.save_user(user_id, auto_notify_time=time_str)
    _remove_jobs(context, user_id)
    _add_daily_job(context, user_id, hour, minute)
    await update.message.reply_text(f"✅ Буду напоминать каждый день в {time_str}.")


# ── Scheduled job callback ─────────────────────────────────────────────────────

async def notify_leaving(context: ContextTypes.DEFAULT_TYPE) -> None:
    user_id: int = context.job.data
    user = await db.get_user(user_id)
    if not user or user["work_lat"] is None or user["home_lat"] is None:
        return

    routes = await gis.get_transit_routes(
        user["work_lat"], user["work_lon"],
        user["home_lat"], user["home_lon"],
        departure_time=datetime.now(),
    )

    if not routes:
        await context.bot.send_message(user_id, "⏰ Пора выходить! Маршруты не найдены.")
        return

    text = _format_routes(routes, "⏰ *Пора выходить! Ближайшие автобусы:*")
    await context.bot.send_message(user_id, text, parse_mode="Markdown")


# ── Job helpers ────────────────────────────────────────────────────────────────

def _remove_jobs(context: ContextTypes.DEFAULT_TYPE, user_id: int) -> None:
    for job in context.job_queue.get_jobs_by_name(str(user_id)):
        job.schedule_removal()


def _add_daily_job(
    context: ContextTypes.DEFAULT_TYPE, user_id: int, hour: int, minute: int
) -> None:
    from datetime import time as dtime
    context.job_queue.run_daily(
        notify_leaving,
        time=dtime(hour=hour, minute=minute),
        name=str(user_id),
        data=user_id,
        job_kwargs={"misfire_grace_time": 300},
    )


# ── ConversationHandler builder ────────────────────────────────────────────────

def build_conv_handler() -> ConversationHandler:
    return ConversationHandler(
        entry_points=[
            CommandHandler("start", start),
            CommandHandler("setwork", setwork_command),
            CommandHandler("sethome", sethome_command),
        ],
        states={
            WORK_ADDRESS: [
                MessageHandler(filters.LOCATION, receive_work_address),
                MessageHandler(filters.TEXT & ~filters.COMMAND, receive_work_address),
            ],
            HOME_ADDRESS: [
                MessageHandler(filters.LOCATION, receive_home_address),
                MessageHandler(filters.TEXT & ~filters.COMMAND, receive_home_address),
            ],
        },
        fallbacks=[CommandHandler("cancel", cancel)],
    )
