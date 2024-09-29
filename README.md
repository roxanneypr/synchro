# Synchro Copy Trading Bot

Synchro is a copy trading bot designed to synchronize trades from a sender account to a receiver account using MetaTrader 4 (MT4) instances. The bot reads trades from a CSV file, processes them, and executes corresponding trades in the receiver account with specified adjustments (according to my account's risk capacity and sender account's trades) such as different lot sizes and symbols.

## Features

- Copies trades from a sender to a receiver account.
- Executes new trades and closes matching trades on the receiver account.
- Configurable lot sizes for receiver trades
- Supports opening additional buy/sell limit orders at specific intervals.
- Handles different trade symbols and suffixes between accounts.
- Option to enable or disable trade copying for both opening and closing trades.
- Time-based filters to prevent old trades from being copied (e.g., only trades within the last 3 minutes are executed).

## Components

- **Trade Execution:** Opens buy/sell trades and places two additional buy/sell limit orders.
- **Trade Management:** Closes all trades with a specific symbol on the receiver account.
- **File Reading:** Reads from `trades.csv` to sync trades.
- **Configurable Symbol Suffix:** Adjusts the trade symbols if the receiver account uses suffixes (e.g., ".s" for symbols).
- **Logging and Debugging:** Prints detailed logs for tracking trade execution and errors.

## Installation

1. **Prerequisites:**

   - Install [MetaTrader 4 (MT4)](https://www.metatrader4.com) on both the sender and receiver accounts.
   - Set up `trades.csv` in the appropriate folder

2. **Setup MetaTrader 4 Instances:**

   - Run two instances of MT4, one for the sender and one for the receiver account.
   - The receiver account must have the `Synchro` Expert Advisor (EA) installed to sync trades.

3. **Receiver EA Setup:**

   - Place the `Synchro` EA file in the MT4 `Experts` folder.
   - Modify the `symbolSuffix` variable in the code if your broker uses suffixes (e.g., `.s` for symbols).

4. **Configuration Options:**
   - **Lot Size Configuration:** You can adjust the lot sizes in the EA code to match your requirements.
   - **Enable/Disable Trade Copying:** Use the options provided in the EA to enable/disable copying of trades for opening or closing positions.

## Usage

1. **Start the EA on the Receiver Account:**

   - Attach the `Synchro` EA to the chart in the receiver account.
   - The EA will automatically start reading from the `trades.csv` file and execute or close trades accordingly.

2. **Monitor Logs:**
   - View the MT4 terminal’s Expert log for detailed trade execution logs and potential error messages.

## Notes

- **Trade Execution:** The bot only executes trades that have occurred within the last 3 minutes to avoid executing outdated trades.
- **Trade Closure:** When closing trades, the EA closes all trades associated with the same symbol, regardless of lot size.
- **Trade Symbols:** Ensure that the trade symbols in the `trades.csv` file match the symbols used by your receiver account, adjusting for suffixes if necessary.

## Future Development

Synchro is currently in development and testing.

## License

This project is for personal use only and is not licensed for distribution or commercial use.
