import times

type
    EqBar* = tuple[
        tstamp: Time,
        barOpen: float,
        barHigh: float,
        barLow: float,
        barClose: float,
        adjClose: float
    ]
    AdBar* = tuple[
        tstamp: Time,
        adjOpen: float,
        adjHigh: float,
        adjLow: float,
        adjClose: float
    ]
    FxBar* = tuple[
        tstamp: Time,
        barOpen: float,
        barHigh: float,
        barLow: float,
        barClose: float
    ]
    TopOfBook* = tuple[
        prevClose: float,
        mid: float,
        lastSaleTime: Time,
        open: float,
        low: float,
        tstamp: Time,
        quoteTstamp: Time,
        lastSize: int,
        last: float,
        high: float,
        askPrice: float,
        askSize: int,
        bidPrice: float,
        bidSize: int,
        volume: int
    ]
