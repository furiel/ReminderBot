import hy
import telegramfetcher, httpserversimulator
import pprint, ssl, pytest

@pytest.fixture
def http_server():
    httpserver =  httpserversimulator.HttpServerSimulator()
    httpserver.start()
    yield httpserver
    httpserver.stop()

@pytest.fixture
def telegram_fetcher():
    fetcher = telegramfetcher.TelegramFetcher("secret_bot_id")
    fetcher.connect(host="localhost:5555", context=ssl._create_unverified_context())
    yield fetcher
    fetcher.disconnect()

simple_message = '{"ok":true,"result":[{"update_id":9999,\n"message":{"message_id":12345,"from":{"id":12456,"is_bot":false,"first_name":"first_name","last_name":"last_name","username":"test_user","language_code":"en-US"},"chat":{"id":1111,"first_name":"first_name","last_name":"last_name","username":"test_user","type":"private"},"date":1540272431,"text":"/later 5 testmessage"}}]}'

def test_fetch_messages(http_server, telegram_fetcher):
    http_server.feed_data(simple_message)
    instant_messages, timers = telegram_fetcher.fetch()
    timer = timers[0]

    assert timer["timeout"] == 5
    assert timer["message"] == "testmessage"

def test_largest_update_id(telegram_fetcher):
    some_ids = [{"update_id": 1}, {"update_id": 5}, {"update_id": 7}]
    telegram_fetcher.update_largest_update_id(some_ids)
    assert telegram_fetcher.last_id == 8
