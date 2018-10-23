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

simple_message = '{"ok":true,"result":[{"update_id":9999,\n"message":{"message_id":12345,"from":{"id":12456,"is_bot":false,"first_name":"first_name","last_name":"last_name","username":"test_user","language_code":"en-US"},"chat":{"id":1111,"first_name":"first_name","last_name":"last_name","username":"test_user","type":"private"},"date":1540272431,"text":"test_message"}}]}'

def test_fetch_messages(http_server, telegram_fetcher):
    http_server.feed_data(simple_message)
    messages = telegram_fetcher.fetch()
    message = messages[0]

    assert message["chat"] == 1111
    assert message["from"] == "test_user"
    assert message["message"] == "test_message"
    assert message["update-id"] == 9999
