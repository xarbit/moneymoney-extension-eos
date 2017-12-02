-- Inofficial EOS Token Distribution Extension for MoneyMoney
-- Fetches EOS Token quantity for address via etherscan API
-- Fetches EOS price in EUR via cryptocompare API
-- Returns cryptoassets as securities
--
-- Username: EOS Token Adresses comma seperated
-- Password: Etherscan API-Key

-- MIT License

-- Copyright (c) 2017 Jason Scurtu

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.1,
  description = "Include your EOS Token as cryptoportfolio in MoneyMoney by providing a EOS Etheradresses (usernme, comma seperated) and etherscan-API-Key (Password)",
  services= { "EOS Token" }
}

local eosAddresses
local etherscanApiKey
local contractAddress = "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0"
local connection = Connection()
local currency = "EUR" -- fixme: make dynamik if MM enables input field

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "EOS Token"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  eosAddresses = username:gsub("%s+", "")
  etherscanApiKey = password
end

function ListAccounts (knownAccounts)
  local account = {
    name = "EOS Token",
    accountNumber = "Crypto Asset EOS Token",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  prices = requestEosPrice()

  for address in string.gmatch(eosAddresses, '([^,]+)') do
    weiQuantity = requestWeiQuantityForEosAddress(address)
    eosQuantity = convertWeiToEos(weiQuantity)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "cryptocompare",
      quantity = eosQuantity,
      price = prices["EUR"],
    }
  end

  return {securities = s}
end

function EndSession ()
end

-- Querry Functions
function requestEosPrice()
  content = connection:request("GET", cryptocompareRequestUrl(), {})
  json = JSON(content)

  return json:dictionary()
end

function requestWeiQuantityForEosAddress(eosAddress)
  content = connection:request("GET", etherscanRequestUrl(eosAddress), {})
  json = JSON(content)

  return json:dictionary()["result"]
end


-- Helper Functions
function convertWeiToEos(wei)
  return wei / 1000000000000000000
end

function cryptocompareRequestUrl()
  return "https://min-api.cryptocompare.com/data/price?fsym=EOS&tsyms=EUR,USD"
end

function etherscanRequestUrl(eosAddress)
  etherscanRoot = "https://api.etherscan.io/api?"
  params = "&module=account&action=tokenbalance&tag=latest&contractaddress=" .. contractAddress
  address = "&address=" .. eosAddress
  apiKey = "&apikey=" .. etherscanApiKey

  return etherscanRoot .. params .. address .. apiKey
end

