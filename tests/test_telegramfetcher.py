import hy
import telegramfetcher, httpserversimulator
import pprint, ssl, pytest, json

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


def test_allowed_users(http_server):
    telegram_fetcher = telegramfetcher.TelegramFetcher("secret_bot_id", allowed_users="user1,user3")
    telegram_fetcher.connect(host="localhost:5555", context=ssl._create_unverified_context())

    msg = \
    '''{"result":[
      {"update_id":9999,"message":{"from":{"username":"user1"},"chat":{"id":12456},"text":"/later 1 user1"}},
      {"update_id":9999,"message":{"from":{"username":"user2"},"chat":{"id":12456},"text":"/later 1 user2"}},
      {"update_id":9999,"message":{"from":{"username":"user3"},"chat":{"id":12456},"text":"/later 1 user3"}},
      {"update_id":9999,"message":{"from":{"username":"user4"},"chat":{"id":12456},"text":"/later 1 user4"}}
    ]}'''

    http_server.feed_data(msg)

    instant_messages, timers = telegram_fetcher.fetch()

    assert len(timers) == 2
    assert timers[0]["message"] == "user1"
    assert timers[1]["message"] == "user3"

    telegram_fetcher.disconnect()
