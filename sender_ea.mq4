// Array to keep track of written open trades
int writtenTrades[];  // This will store the trade ticket numbers that have already been written as "OPEN"

int OnInit() {
    Print("EA initialized");
    ArrayResize(writtenTrades, 0);  // Initialize an empty array

    // Load previously written trades from the file
    LoadWrittenTrades();
    // Test writing to the file
    //TestFileWrite();

    return INIT_SUCCEEDED;
}

void OnTick() {
    datetime currentTime = TimeCurrent();

    int totalOrders = OrdersTotal();
    //Print("Total open orders: ", totalOrders);

    // Loop through all open positions (new and still open trades)
    for (int i = 0; i < totalOrders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            int openTicket = OrderTicket();  // Get the trade ticket number for open trades
            //Print("Found open trade with ticket: ", openTicket);

            // Check if this trade has already been written as "OPEN"
            if (FindTicketInArray(writtenTrades, openTicket) == -1) {
                Print("Saving open trade with ticket: ", openTicket);
                SaveTradeToFile(openTicket, OrderSymbol(), OrderType(), OrderLots(), OrderOpenPrice(), "OPEN");

                // Add the ticket to the array to ensure it's only written once
                ArrayResize(writtenTrades, ArraySize(writtenTrades) + 1);
                writtenTrades[ArraySize(writtenTrades) - 1] = openTicket;
            }
        }
    }

    // Periodically check if trades in `writtenTrades[]` have been closed
    for (int j = 0; j < ArraySize(writtenTrades); j++) {  // Use 'j' here to avoid conflict with 'i'
        int ticket = writtenTrades[j];

        // In OnTick function
        if (IsTradeClosed(ticket)) {
            Print("Trade with ticket ", ticket, " has been closed.");
            if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
                // If the trade is successfully selected
                SaveTradeToFile(ticket, OrderSymbol(), OrderType(), OrderLots(), OrderClosePrice(), "CLOSE");

                // Remove the ticket from the open trades list
                RemoveTicketFromArray(writtenTrades, ticket);

                // Since the array size has changed, reduce the index to prevent skipping elements
                j--;
            } else {
                Print("Error selecting closed trade with ticket: ", ticket);
            }
        }
    }
}

// Function to check if a specific trade (by ticket) is closed
bool IsTradeClosed(int ticket) {
    // Select the trade by ticket number in the history
    if (OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
        if (OrderCloseTime() > 0) {  // If there is a close time, the trade is closed
            return true;
        }
    }
    return false;  // The trade is still open if no close time is found
}

// Function to remove a ticket from the writtenTrades array
void RemoveTicketFromArray(int &arr[], int ticket) {
    int index = FindTicketInArray(arr, ticket);
    if (index != -1) {
        // Shift elements after the found index to the left
        for (int i = index; i < ArraySize(arr) - 1; i++) {
            arr[i] = arr[i + 1];
        }
        // Resize the array to remove the last element
        ArrayResize(arr, ArraySize(arr) - 1);
    }
}

// Function to append trade details to a file
void SaveTradeToFile(int ticket, string symbol, int type, double lots, double price, string action) {
    // Open the file for writing and appending (no need for reading here)
    int handle = FileOpen("tothemoon/trades.csv", FILE_WRITE | FILE_READ | FILE_CSV, ";");
    
    if (handle == INVALID_HANDLE) {
        Print("Error opening or creating trades.csv in the folder");
        return;
    }

    // Seek to the end of the file for appending
    FileSeek(handle, 0, SEEK_END);

    // Write the trade data to the file (including open or close action)
    FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES), ticket, symbol, type, lots, price, action);

    // Close the file after writing
    FileClose(handle);
    Print("Trade saved to file: ", symbol, " ", action);
}


// Function to load previously written trades from the file
void LoadWrittenTrades() {
    int handle = FileOpen("tothemoon/trades.csv", FILE_READ | FILE_CSV, ";");

    if (handle == INVALID_HANDLE) {
        Print("Error opening trades.csv for reading.");
        return;
    }

    while (!FileIsEnding(handle)) {

        // Read each value in the correct order based on the CSV structure
        string timestamp = FileReadString(handle);  // Read the timestamp
        if (StringLen(timestamp) == 0) {
            continue;  // Skip empty lines
        }
        
        string tix = FileReadString(handle);       // Read the ticket number (integer)
        string symbol = FileReadString(handle);     // Read the symbol (currency pair)
        string type = FileReadString(handle);         // Read the trade type (integer)
        string lots = FileReadString(handle);       // Read the lot size (double)
        string price = FileReadString(handle);      // Read the price (double)
        string action = FileReadString(handle);     // Read the action (OPEN or CLOSE)
        int ticket = StrToInteger(tix);  // Convert the ticket string to an integer

        // Debugging print to ensure correct reading
        Print("Read from file -> Timestamp: ", timestamp, " Ticket: ", ticket, " Symbol: ", symbol, " Type: ", type, " Lots: ", lots, " Price: ", price, " Action: ", action);

        // Validate the data before adding it to the array
        if (ticket > 0 && action == "OPEN" && FindTicketInArray(writtenTrades, ticket) == -1) {
            // Add the trade ticket to the writtenTrades array if it's still open
            ArrayResize(writtenTrades, ArraySize(writtenTrades) + 1);
            writtenTrades[ArraySize(writtenTrades) - 1] = ticket;

            Print("Loaded trade ticket: ", ticket, " into writtenTrades array.");
        } else if (FindTicketInArray(writtenTrades, ticket) != -1) {
            Print("Trade ticket ", ticket, " is already loaded, skipping.");
        }
    }

    FileClose(handle);
    Print("Finished loading previously written trades.");
}

// Custom function to find a ticket in the array
int FindTicketInArray(int &arr[], int ticket) {
    for (int i = 0; i < ArraySize(arr); i++) {
        if (arr[i] == ticket) {
            return i;  // Ticket found in the array
        }
    }
    return -1;  // Ticket not found
}


// Function to test writing to a file
void TestFileWrite() {
    // Open the file for writing and appending
    int handle = FileOpen("tothemoon/test.csv", FILE_WRITE | FILE_READ | FILE_CSV, ";");

    if (handle == INVALID_HANDLE) {
        Print("Error opening or creating testfile.csv");
        return;
    }

    // Seek to the end of the file for appending
    FileSeek(handle, 0, SEEK_END);

    // Write test data to the file
    FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES), "TestfLine 1");
    FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES), "TestLine 2");
    FileWrite(handle, TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES), "TestLine 3");

    // Close the file after writing
    FileClose(handle);

    Print("Test file written successfully.");
}