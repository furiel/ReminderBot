(import asyncio os select logging)

(defclass TimerDB [object]
  (defn --init-- [self]
    (setv self.loop (asyncio.new_event_loop)))

  (defn start [self]
    (logging.info "TimerDB started")
    (asyncio.set_event_loop self.loop)
    (self.loop.run_forever))

  (defn stop [self]
    (logging.info "TimerDB stopped")
    (self.loop.call_soon_threadsafe self.loop.stop))

  (defn add-timer [self when action]
    (self.loop.call_soon_threadsafe self.loop.call_later when action)))
