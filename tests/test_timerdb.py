import hy
from timerdb import *
import pytest, threading
import time

def test_start_stop_without_crash():
    timer_db = TimerDB()
    thread = threading.Thread(target=timer_db.start)
    thread.start()
    timer_db.stop()

def test_two_timers():
    timer_db = TimerDB()
    thread = threading.Thread(target=timer_db.start)
    thread.start()

    acknowledgements = []

    timer_db.add_timer(0.2, lambda : acknowledgements.append(True))
    timer_db.add_timer(0.2, lambda : acknowledgements.append(True))
    time.sleep(1)
    timer_db.stop();

    assert len(acknowledgements) == 2
