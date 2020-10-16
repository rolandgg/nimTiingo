import httpclient
import times, strformat, json, algorithm, strutils
import nimTiingo/bartypes
import tables

export
  bartypes

type
  TiingoClient = ref object
    http: HttpClient
    apiKey: string

proc parseTopofBook(data: JsonNode): TopOfBook {.inline.}=
  result.prevClose = data["prevClose"].getFloat
  result.mid = data["mid"].getFloat
  result.lastSaleTime = parse(data["lastSaleTimestamp"].getStr, "yyyy-MM-dd'T'hh:mm:sszzz").toTime
  result.open = data["open"].getFloat
  result.askPrice = data["askPrice"].getFloat
  result.low = data["low"].getFloat
  result.tstamp = parse(data["timestamp"].getStr, "yyyy-MM-dd'T'hh:mm:sszzz").toTime
  result.quoteTstamp = parse(data["quoteTimestamp"].getStr, "yyyy-MM-dd'T'hh:mm:sszzz").toTime
  result.bidPrice = data["bidPrice"].getFloat
  result.bidSize = data["bidSize"].getInt
  result.askSize = data["askSize"].getInt
  result.volume = data["volume"].getInt

proc newTiingoClient*(key: string): TiingoClient =
  new(result)
  result.http = newHttpClient()
  result.apiKey = key


proc requestStockData*(client: TiingoClient, startDate: DateTime, endDate: DateTime, symbol: string): tuple[data: seq[EqBar], adj: seq[AdBar]] =
  let startstr = startDate.format("yyyy-M-d")
  let endstr = endDate.format("yyyy-M-d")
  let raw = client.http.getContent(fmt"https://api.tiingo.com/tiingo/daily/{symbol}/prices?token={client.apiKey}&startDate={startstr}&endDate={endstr}&format=json&resampleFreq=daily")
  let data = parseJson(raw)
  var eqbars: seq[EqBar] = @[]
  var adbars: seq[AdBar] = @[]
  var tstamp: Time
  for bar in data.elems:
    tstamp = parse(bar["date"].getStr, "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'").toTime
    eqbars.add((tstamp: tstamp, barOpen: bar["open"].getFloat, barHigh: bar["high"].getFloat, barLow: bar["low"].getFloat,
      barClose: bar["close"].getFloat, adjClose: bar["adjClose"].getFloat))
    adbars.add((tstamp: tstamp, adjOpen: bar["adjOpen"].getFloat, adjHigh: bar["adjHigh"].getFloat, adjLow: bar["adjLow"].getFloat, adjClose: bar["adjClose"].getFloat))
  eqbars.sort do (x, y: EqBar) -> int:
    result = cmp(y.tstamp, x.tstamp)
  adbars.sort do (x, y: AdBar) -> int:
    result = cmp(y.tstamp, x.tstamp)
  return (data: eqbars, adj: adbars)

proc requestIEXTopOfBook*(client: TiingoClient, symbol: string): TopOfBook =
  let raw = client.http.getContent(fmt"https://api.tiingo.com/iex/?tickers={symbol}&token={client.apiKey}")
  let data = parseJson(raw)[0]
  parseTopofBook(data)
  

proc requestIEXTopOfBookMulti*(client: TiingoClient, symbols: openArray[string]): Table[string,TopOfBook] =
  var serial = join(symbols, ",")
  let raw = client.http.getContent(fmt"https://api.tiingo.com/iex/?tickers={serial}&token={client.apiKey}")
  let data = parseJson(raw)
  result = initTable[string,TopOfBook]()
  for ticker in data:
    result[ticker["ticker"].getStr] = parseTopofBook(ticker)

proc requestFXData*(client: TiingoClient, startDate: DateTime, symbol: string): seq[FxBar] =
    let startstr = startDate.format("yyyy-M-d")
    let raw = client.http.getContent(fmt"https://api.tiingo.com/tiingo/fx/{symbol}/prices?startDate={startstr}&resampleFreq=1Day&token={client.apiKey}")
    let data = parseJson(raw)
    var tstamp: Time
    result = @[]
    for bar in data.elems:
        tstamp = parse(bar["date"].getStr, "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'").toTime
        result.add((tstamp: tstamp, barOpen: bar["open"].getFloat, barHigh: bar["high"].getFloat, barLow: bar["low"].getFloat,
        barClose: bar["close"].getFloat))

if isMainModule:
    let startDate = initDateTime(1, mJul, 2019, 0,0,0)
    let endDate = initDateTime(31, mJul, 2019, 0,0,0)
    var client = newTiingoClient("8e6934b3aac8d59a5eb749708d41b1563061aa24")
    echo client.requestIEXTopOfBookMulti(["AAPL","MSFT"])