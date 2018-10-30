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
        assert set([objects[0]["test_field"], objects[1]["test_field"]]) == set(["test1", "test2"])

        persist_state.remove(2)

        assert not os.path.exists(os.path.join(tempdir, "{}.persist".format(2)))

def test_corruptstate():
    with tempfile.TemporaryDirectory() as tempdir:
        persist_state = persiststate.PersistState(tempdir)

        with open(os.path.join(tempdir, "1.persist"), "w") as f:
            f.write('{"id": 1, "imbalanced" : "parentheses"')

        assert (len(persist_state.load_all())) == 0
