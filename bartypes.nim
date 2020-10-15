import times

type
    EqBar* = object
        tstamp*: Time
        barOpen*: float
        barHigh*: float
        barLow*: float
        barClose*: float
        adjClose*: float
    AdBar* = object
        tstamp*: Time
        adjOpen*: float
        adjHigh*: float
        adjLow*: float
        adjClose*: float
    FxBar* = object
        tstamp*: Time
        barOpen*: float
        barHigh*: float
        barLow*: float
        barClose*: float
    AssetRow* = object
        ticker*: string
        momentum*: float
        ma200*: float
        ma100*: float
        gap*: float
        lastPrice*: float
        atr*: float
        allocation*: float
        shares*: int
