import httpclient
import times, strformat, json, algorithm, strutils
import nimTiingo/bartypes
import tables
import asyncdispatch

export
  bartypes

type
  TiingoClient = ref object
    http: AsyncHttpClient
    apiKey: string

proc parseRealTimeTS(tstamp: string): Time =
  try:
    result = parse(tstamp, "yyyy-MM-dd'T'hh:mm:ss'.'fffffffffzzz").toTime
  except TimeParseError:
    result = parse(tstamp, "yyyy-MM-dd'T'hh:mm:sszzz").toTime

proc parseTopofBook(data: JsonNode): TopOfBook {.inline.}=
  result.prevClose = data["prevClose"].getFloat
  result.mid = data["mid"].getFloat
  result.lastSaleTime = parseRealTimeTS(data["lastSaleTimestamp"].getStr)
  result.open = data["open"].getFloat
  result.askPrice = data["askPrice"].getFloat
  result.low = data["low"].getFloat
  result.tstamp = parseRealTimeTS(data["timestamp"].getStr)
  result.quoteTstamp = parseRealTimeTS(data["quoteTimestamp"].getStr)
  result.bidPrice = data["bidPrice"].getFloat
  result.bidSize = data["bidSize"].getInt
  result.askSize = data["askSize"].getInt
  result.volume = data["volume"].getInt

proc newTiingoClient*(key: string): TiingoClient =
  new(result)
  result.http = newAsyncHttpClient()
  result.apiKey = key


proc requestStockData*(client: TiingoClient, startDate: DateTime, endDate: DateTime, symbol: string): Future[tuple[data: seq[EqBar], adj: seq[AdBar]]] {.async.} =
  let startstr = startDate.format("yyyy-M-d")
  let endstr = endDate.format("yyyy-M-d")
  let raw = await client.http.getContent(fmt"https://api.tiingo.com/tiingo/daily/{symbol}/prices?token={client.apiKey}&startDate={startstr}&endDate={endstr}&format=json&resampleFreq=daily")
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

proc requestIEXTopOfBook*(client: TiingoClient, symbol: string): Future[TopOfBook] {.async.} =
  let raw = await client.http.getContent(fmt"https://api.tiingo.com/iex/?tickers={symbol}&token={client.apiKey}")
  let data = parseJson(raw)[0]
  return parseTopofBook(data)
  

proc requestIEXTopOfBookMulti*(client: TiingoClient, symbols: openArray[string]): Future[Table[string,TopOfBook]] {.async.} =
  var serial = join(symbols, ",")
  let raw = await client.http.getContent(fmt"https://api.tiingo.com/iex/?tickers={serial}&token={client.apiKey}")
  let data = parseJson(raw)
  result = initTable[string,TopOfBook]()
  for ticker in data:
    result[ticker["ticker"].getStr] = parseTopofBook(ticker)

proc requestFXData*(client: TiingoClient, startDate: DateTime, symbol: string): Future[seq[FxBar]] {.async.} =
    let startstr = startDate.format("yyyy-M-d")
    let raw = await client.http.getContent(fmt"https://api.tiingo.com/tiingo/fx/{symbol}/prices?startDate={startstr}&resampleFreq=1Day&token={client.apiKey}")
    let data = parseJson(raw)
    var tstamp: Time
    result = @[]
    for bar in data.elems:
        tstamp = parse(bar["date"].getStr, "yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'").toTime
        result.add((tstamp: tstamp, barOpen: bar["open"].getFloat, barHigh: bar["high"].getFloat, barLow: bar["low"].getFloat,
        barClose: bar["close"].getFloat))