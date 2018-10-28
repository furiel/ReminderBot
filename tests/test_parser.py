import hy
from parser import *
import pytest

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

def test_parse_input():
    assert (10, "hello") == parse_input("/later 10s hello")
