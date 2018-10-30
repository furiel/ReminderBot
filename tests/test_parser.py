import hy
from parser import *
import pytest, datetime, math

def test_timeout_conversion():
    with pytest.raises(ValueError):
        timeout_to_sec("")
    with pytest.raises(ValueError):
        timeout_to_sec("text")
    with pytest.raises(ValueError):
        timeout_to_sec("1A1")

    assert 10 == timeout_to_sec("10")
    assert 10 == timeout_to_sec("10s")
    assert 60 * 10 == timeout_to_sec("10m")
    assert 60 * 60 * 10 == timeout_to_sec("10h")

def test_parse_later():
    assert (10, "testmessage") == parse_input("/later 10s testmessage")
    assert (10, "multiple word message") == parse_input("/later 10s multiple word message")

def test_parse_at():
    when = (datetime.datetime.now() + datetime.timedelta(minutes=1)).strftime("%Y:%m:%d::%H:%M:%S")
    assert (60, "testmessage") == parse_input("/at {} testmessage".format(when))
