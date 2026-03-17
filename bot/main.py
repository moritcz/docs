import logging

from telegram.ext import Application, CommandHandler

from config import TELEGRAM_TOKEN
from database import init_db
from handlers import (
    build_conv_handler,
    leaving_command,
    route_command,
    schedule_command,
)
from scheduler import restore_jobs

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
log = logging.getLogger(__name__)


async def post_init(app: Application) -> None:
    await init_db()
    await restore_jobs(app)
    log.info("Bot is ready.")


def main() -> None:
    app = (
        Application.builder()
        .token(TELEGRAM_TOKEN)
        .post_init(post_init)
        .build()
    )

    app.add_handler(build_conv_handler())
    app.add_handler(CommandHandler("route", route_command))
    app.add_handler(CommandHandler("leaving", leaving_command))
    app.add_handler(CommandHandler("schedule", schedule_command))

    log.info("Starting polling…")
    app.run_polling()


if __name__ == "__main__":
    main()
