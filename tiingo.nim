import httpclient
import times, strformat, json, algorithm, sugar
import bartypes
const API_Key = "8e6934b3aac8d59a5eb749708d41b1563061aa24"


proc requestTiingo*(client: HttpClient, startDate: DateTime, endDate: DateTime, symbol: string): tuple[data: seq[EqBar], adj: seq[AdBar]] =
    let startstr = startDate.format("yyyy-M-d")
    echo startstr
    let endstr = endDate.format("yyyy-M-d")
    echo endstr
    let raw = client.getContent(fmt"https://api.tiingo.com/tiingo/daily/{symbol}/prices?token={API_Key}&startDate={startstr}&endDate={endstr}&format=json&resampleFreq=daily")
    let data = parseJson(raw)
    var eqbars: seq[EqBar] = @[]
    var adbars: seq[AdBar] = @[]
    var tstamp: Time
    for bar in data.elems:
        tstamp = parse(bar["date"].getStr, "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'").toTime
        eqbars.add(EqBar(tstamp: tstamp, barOpen: bar["open"].getFloat, barHigh: bar["high"].getFloat, barLow: bar["low"].getFloat,
         barClose: bar["close"].getFloat, adjClose: bar["adjClose"].getFloat))
        adbars.add(AdBar(tstamp: tstamp, adjOpen: bar["adjOpen"].getFloat, adjHigh: bar["adjHigh"].getFloat, adjLow: bar["adjLow"].getFloat, adjClose: bar["adjClose"].getFloat))
    eqbars.sort do (x, y: EqBar) -> int:
        result = cmp(y.tstamp, x.tstamp)
    adbars.sort do (x, y: AdBar) -> int:
        result = cmp(y.tstamp, x.tstamp)
    return (data: eqbars, adj: adbars)

proc requestTiingoFX*(client: HttpClient, startDate: DateTime, symbol: string): seq[FxBar] =
    let startstr = startDate.format("yyyy-M-d")
    let raw = client.getContent(fmt"https://api.tiingo.com/tiingo/fx/{symbol}/prices?startDate={startstr}&resampleFreq=1Day&token={API_Key}")
    let data = parseJson(raw)
    var tstamp: Time
    result = @[]
    for bar in data.elems:
        tstamp = parse(bar["date"].getStr, "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'").toTime
        result.add(FxBar(tstamp: tstamp, barOpen: bar["open"].getFloat, barHigh: bar["high"].getFloat, barLow: bar["low"].getFloat,
        barClose: bar["close"].getFloat))
if isMainModule:
    let startDate = initDateTime(1, mJul, 2019, 0,0,0)
    let endDate = initDateTime(31, mJul, 2019, 0,0,0)
    var client = newHttpClient()
    #let (eqbars, adbars) = client.requestTiingo(startDate, endDate, "AAPL")
    #echo eqbars
    #let fxdata = client.requestTiingoFX(startDate, "eurusd")