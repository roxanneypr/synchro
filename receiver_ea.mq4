// Define the magic number for this EA
#define MAGIC_NUMBER 0

// Input parameters to enable or disable copying of trades
input bool enableOpenTrades = true;   // Enable or disable copying of open trades
input bool enableCloseTrades = true;  // Enable or disable copying of close trades

// Array to keep track of executed trades using timestamp+symbol+lots as the unique key
string executedTrades[];
string symbolSuffix = ".s";  // Define the symbol suffix for the receiver account (adjust this as needed)
int tradeTimeLimit = 180;  // 3 minutes in seconds

// Function to initialize the EA
int OnInit() {
    TestFileReading();  // Call the test function here

    // Call the function to print currently open trades
    PrintOpenTrades();
    Print("Receiver EA initialized.");
    ArrayResize(executedTrades, 0);  // Initialize an empty array for tracking executed trades
    return INIT_SUCCEEDED;
}

// Function to execute and close trades based on the contents of the trades.csv file
void OnTick() {
    // Open the trades.csv file
    int handle = FileOpen("tothemoon/trades.csv", FILE_READ | FILE_CSV, ";");
    
    if (handle == INVALID_HANDLE) {
        Print("Error opening trades.csv for reading.");
        return;
    }

    while (!FileIsEnding(handle)) {
        // Read each field from the file
        string timestampStr = FileReadString(handle);
        string tix = FileReadString(handle);
        string symbol = FileReadString(handle);
        int type = StringToInteger(FileReadString(handle));  // Trade type (buy/sell)
        double oglots = StringToDouble(FileReadString(handle));
        double price = StringToDouble(FileReadString(handle));
        string action = FileReadString(handle);  // OPEN or CLOSE
        double lots = 0.01;  // Default lot size

        // Convert the timestamp from string to datetime
        datetime tradeTime = StringToTime(timestampStr);

        // Debugging print for timestamp
        //Print("Trade time (CSV): ", timestampStr, " | Trade datetime: ", TimeToString(tradeTime, TIME_DATE | TIME_MINUTES));
        //Print("Symbol: ", symbol, " | Type: ", type, " | Lots: ", lots, " | Price: ", price, " | Action: ", action);
        // Adjust lot size
        if (oglots == 0.50) {
            lots = 0.01;
        }
        // Adjust the symbol for the receiver account (append the suffix)
        string adjustedSymbol = AdjustSymbol(symbol);

        // Create a unique key for this trade using timestamp+symbol+lots
        string uniqueTradeKey = timestampStr + symbol + DoubleToString(lots, 2);

        // Handle OPEN actions (open new trades)
        if (enableOpenTrades && FindTradeInArray(executedTrades, uniqueTradeKey) == -1 && action == "OPEN") {
            // Only open trades executed within the last 3 minutes and not CHF pairs
            if (IsTradeWithinTimeLimit(tradeTime) && !IsChfPair(symbol) && oglots == 0.50) {

                // Check if this trade already exists in the receiver's account (open trades)

                if (!IsTradeAlreadyOpen(adjustedSymbol, lots)) {
                    Print("Executing trade: ", adjustedSymbol, " Type: ", type, " Lots: ", lots);
                    ExecuteTrade(adjustedSymbol, type, lots, price);

                    // Add this trade to the executed trades array to avoid duplication
                    ArrayResize(executedTrades, ArraySize(executedTrades) + 1);
                    executedTrades[ArraySize(executedTrades) - 1] = uniqueTradeKey;
                } else {
                    Print("Trade already open for symbol: ", adjustedSymbol, " with lots: ", lots);
                }
            } else {
                //Print("Skipping trade: ", symbol, " because it's either too old or a CHF pair.");
            }
        }

        // Handle CLOSE actions (close existing trades)
        if (enableCloseTrades && action == "CLOSE") {
            // Attempt to close a matching trade (based on symbol and lots)
            CloseMatchingTrade(adjustedSymbol);
        }
    }

    FileClose(handle);
}

void ExecuteTrade(string symbol, int type, double lots, double price) {
    int slippage = 3;
    int orderTicket;  // Variable to store the order ticket
    double limitPrice; // Variable to store the limit order price
    double firstLimitLots = lots + 0.01;  // First limit order lot size
    double secondLimitLots = firstLimitLots + 0.01;  // Second limit order lot size
    int pipSize = 25; // 25 pips
    // Debugging: Print the symbol before executing the trade
    Print("Executing trade with symbol: ", symbol, " | Lots: ", lots);

    if (type == OP_BUY) {
        // Execute a buy order and check if it was successful
        orderTicket = OrderSend(symbol, OP_BUY, lots, Ask, slippage, 0, 0, "Receiver EA Buy", MAGIC_NUMBER, 0, Green);
        if (orderTicket < 0) {
            // If the order fails, print an error message
            Print("Failed to execute Buy order for ", symbol, " Error code: ", GetLastError());
        } else {
            // Order successful
            Print("Successfully executed Buy order for ", symbol, " Ticket: ", orderTicket);

            // Place the first buy limit 25 pips above the current price
            limitPrice = Ask + (pipSize * Point);  // 25 pips above
            int firstBuyLimitTicket = OrderSend(symbol, OP_BUYLIMIT, firstLimitLots, limitPrice, slippage, 0, 0, "First Buy Limit", MAGIC_NUMBER, 0, Green);
            if (firstBuyLimitTicket < 0) {
                Print("Failed to place First Buy Limit order for ", symbol, " Error code: ", GetLastError());
            } else {
                Print("Successfully placed First Buy Limit order for ", symbol, " at ", limitPrice);

                // Define and place the second buy limit 25 pips above the first limit price
                limitPrice = limitPrice + (pipSize * Point);  // Another 25 pips above
                int secondBuyLimitTicket = OrderSend(symbol, OP_BUYLIMIT, secondLimitLots, limitPrice, slippage, 0, 0, "Second Buy Limit", MAGIC_NUMBER, 0, Green);
                if (secondBuyLimitTicket < 0) {
                    Print("Failed to place Second Buy Limit order for ", symbol, " Error code: ", GetLastError());
                } else {
                    Print("Successfully placed Second Buy Limit order for ", symbol, " at ", limitPrice);
                }
            }
        }
    } else if (type == OP_SELL) {
        // Execute a sell order and check if it was successful
        orderTicket = OrderSend(symbol, OP_SELL, lots, Bid, slippage, 0, 0, "Receiver EA Sell", MAGIC_NUMBER, 0, Red);
        if (orderTicket < 0) {
            // If the order fails, print an error message
            Print("Failed to execute Sell order for ", symbol, " Error code: ", GetLastError());
        } else {
            // Order successful
            Print("Successfully executed Sell order for ", symbol, " Ticket: ", orderTicket);

            // Place the first sell limit 25 pips below the current price
            limitPrice = Bid - (pipSize * Point);  // 25 pips below
            int firstSellLimitTicket = OrderSend(symbol, OP_SELLLIMIT, firstLimitLots, limitPrice, slippage, 0, 0, "First Sell Limit", MAGIC_NUMBER, 0, Red);
            if (firstSellLimitTicket < 0) {
                Print("Failed to place First Sell Limit order for ", symbol, " Error code: ", GetLastError());
            } else {
                Print("Successfully placed First Sell Limit order for ", symbol, " at ", limitPrice);

                // Define and place the second sell limit 25 pips below the first limit price
                limitPrice = limitPrice - (pipSize * Point);  // Another 25 pips below
                int secondSellLimitTicket = OrderSend(symbol, OP_SELLLIMIT, secondLimitLots, limitPrice, slippage, 0, 0, "Second Sell Limit", MAGIC_NUMBER, 0, Red);
                if (secondSellLimitTicket < 0) {
                    Print("Failed to place Second Sell Limit order for ", symbol, " Error code: ", GetLastError());
                } else {
                    Print("Successfully placed Second Sell Limit order for ", symbol, " at ", limitPrice);
                }
            }
        }
    }
}



// Custom function to close all matching trades based on symbol (ignores lot size)
void CloseMatchingTrade(string symbol) {
    int totalOrders = OrdersTotal();
    
    for (int i = 0; i < totalOrders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            // Match the trade by symbol, ignoring the lot size
            if (OrderSymbol() == symbol) {
                double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;  // Close at the current market price
                int slippage = 3;
                bool result = OrderClose(OrderTicket(), OrderLots(), closePrice, slippage, Violet);
                
                if (result) {
                    Print("Successfully closed trade: ", symbol, " | Lots: ", OrderLots());
                } else {
                    Print("Failed to close trade: ", symbol, " | Lots: ", OrderLots());
                }
            }
        }
    }
}


// Custom function to check if a trade with the same symbol and lots is already open
bool IsTradeAlreadyOpen(string symbol, double lots) {
    int totalOrders = OrdersTotal();
    
    for (int i = 0; i < totalOrders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            // Match the trade by symbol and lots
            if (OrderSymbol() == symbol && OrderLots() == lots) {
                return true;  // Trade with this symbol and lot size is already open
            }
        }
    }
    return false;  // No matching trade found
}

// Custom function to adjust the symbol for the receiver account (add suffix)
string AdjustSymbol(string symbol) {
    if (StringFind(symbol, symbolSuffix) == -1) {
        return symbol + symbolSuffix;  // Append the .s suffix if not already present
    }
    return symbol;  // Return the symbol unchanged if suffix is already present
}

// Custom function to find a trade in the executedTrades array
int FindTradeInArray(string &arr[], string tradeKey) {
    for (int i = 0; i < ArraySize(arr); i++) {
        if (arr[i] == tradeKey) {
            return i;  // Trade found in the array
        }
    }
    return -1;  // Trade not found
}

// Custom function to check if the trade was executed within the last 3 minutes
bool IsTradeWithinTimeLimit(datetime tradeTime) {
    // Calculate the time difference between the current time and the trade time
    int timeDifference = TimeCurrent() - tradeTime;

    // Convert time difference to minutes
    double timeDifferenceMinutes = timeDifference / 60.0;

    // Print for debugging to see the time difference in both seconds and minutes
    //Print("Time difference: ", timeDifference, " seconds (", DoubleToString(timeDifferenceMinutes, 2), " minutes)");

    // If the trade is older than 3 minutes (180 seconds), return false
    return (timeDifference <= tradeTimeLimit);
}

// Custom function to check if the symbol is a CHF pair
bool IsChfPair(string symbol) {
    return StringFind(symbol, "CHF") != -1;  // Returns true if "CHF" is found in the symbol
}

// Function to print currently open trades
void PrintOpenTrades() {
    int totalOrders = OrdersTotal();  // Get the total number of open orders

    Print("Total open trades: ", totalOrders);

    // Loop through all open trades
    for (int i = 0; i < totalOrders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {  // Select the trade by its position in the list
            string symbol = OrderSymbol();                // Get the symbol of the trade
            double lots = OrderLots();                    // Get the lot size of the trade
            int type = OrderType();                       // Get the trade type (buy/sell)
            double openPrice = OrderOpenPrice();          // Get the trade open price

            // Print details of the open trade
            if (type == OP_BUY) {
                Print("Open Buy Order: Symbol = ", symbol, " | Lots = ", lots, " | Open Price = ", openPrice);
            } else if (type == OP_SELL) {
                Print("Open Sell Order: Symbol = ", symbol, " | Lots = ", lots, " | Open Price = ", openPrice);
            } else {
                Print("Unknown trade type: ", type);
            }
        } else {
            Print("Failed to select trade at index ", i);
        }
    }
}

void TestFileReading() {
    // Open the trades.csv file
    int handle = FileOpen("tothemoon/trades.csv", FILE_READ | FILE_CSV, ";");
    
    if (handle == INVALID_HANDLE) {
        Print("Error opening trades.csv for reading.");
        return;
    }

    Print("Successfully opened trades.csv.");

    // Loop through the file until the end
    while (!FileIsEnding(handle)) {
        // Read each field from the file
        string timestampStr = FileReadString(handle);
        if (StringLen(timestampStr) == 0) {
            Print("Empty timestamp string, skipping line.");
            continue;  // Skip empty lines
        }

        string tix = FileReadString(handle);
        string symbol = FileReadString(handle);
        int type = StringToInteger(FileReadString(handle));  // Trade type (buy/sell)
        double lots = StringToDouble(FileReadString(handle));
        double price = StringToDouble(FileReadString(handle));
        string action = FileReadString(handle);  // OPEN or CLOSE

        // Convert the timestamp string to datetime
        datetime tradeTime = StringToTime(timestampStr);

        // Calculate the time difference between the trade time and current time
        int timeDifferenceSeconds = TimeCurrent() - tradeTime;
        double timeDifferenceMinutes = timeDifferenceSeconds / 60.0;

        // Print each field to the Experts log for debugging
        Print("Read line: Timestamp=", timestampStr, ", Symbol=", symbol, ", Type=", type, 
              ", Lots=", lots, ", Price=", price, ", Action=", action, 
              ", Time Difference=", timeDifferenceSeconds, " seconds (", 
              DoubleToString(timeDifferenceMinutes, 2), " minutes)");

        // Optional: If you want to parse the fields for further processing, use these:
        int typeInt = StringToInteger(type);
        double lotsDouble = StringToDouble(lots);
        double priceDouble = StringToDouble(price);
    }

    FileClose(handle);
    Print("Finished reading trades.csv.");
}

