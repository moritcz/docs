import logging
from datetime import time as dtime

from telegram.ext import Application

import database as db
from handlers import notify_leaving, _add_daily_job

log = logging.getLogger(__name__)


async def restore_jobs(app: Application) -> None:
    """Re-register daily notification jobs from the database after bot restart."""
    users = await db.get_all_users_with_schedule()
    restored = 0
    for user in users:
        time_str: str = user["auto_notify_time"]
        try:
            hour, minute = map(int, time_str.split(":"))
        except (ValueError, AttributeError):
            log.warning("Invalid notify time for user %s: %s", user["user_id"], time_str)
            continue

        # Build a minimal context-like object to reuse _add_daily_job
        class _FakeCtx:
            job_queue = app.job_queue

        _add_daily_job(_FakeCtx(), user["user_id"], hour, minute)
        restored += 1

    log.info("Restored %d scheduled notification(s).", restored)
