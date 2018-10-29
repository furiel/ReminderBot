import hy
import persiststate
import pytest, tempfile, os

def test_persiststate():
    with tempfile.TemporaryDirectory() as tempdir:
        persist_state = persiststate.PersistState(tempdir)
        obj1 = {"id" : 1, "test_field" : "test1"}
        obj2 = {"id" : 2, "test_field" : "test2"}
        persist_state.save(1, obj1)
        persist_state.save(2, obj2)

        objects = persist_state.load_all()
        assert objects[0]["test_field"] == "test1"
        assert objects[1]["test_field"] == "test2"

        persist_state.remove(2)

        assert not os.path.exists(os.path.join(tempdir, "{}.persist".format(2)))
