//+------------------------------------------------------------------+
//|                                     XAUUSD_BasketTrailing_EA.mq5 |
//|                                                       Talha Khan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Talha Khan"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>

// ===== ORIGINAL INPUTS =====
input double   StartLot       = ;
input double   LotStep        = ;
input int      MaxTrades      = ;
input int      StepPoints     = ;
input int      TrailPoints    = ;         // Basket trailing distance (points)
input int      MaxLossPoints  = ;       // Basket max loss (points)
input string   TradeSymbol    = "XAUUSDm";
input int ProfitLockStartPoints = 100; // start locking only after this profit

input ENUM_TIMEFRAMES TF      = PERIOD_M1;

// ===== GLOBALS =====
double LastOpenPrice = 0.0;
int    LastDirection = 0;
double PeakPoints    = 0.0;                  // Peak profit in POINTS
double LockedPoints = 0.0;

CTrade trade;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA Initialized (Basket SL + Basket Trailing, Point-Based)");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(StringFind(_Symbol, TradeSymbol) != 0) return;

   int totalPositions = CountPositionsForSymbol(TradeSymbol);

   // --- Trend detection (unchanged)
   double openCandle  = iOpen(TradeSymbol, TF, 0);
   double closeCandle = iClose(TradeSymbol, TF, 0);
   int trend = (closeCandle > openCandle) ? 1 : -1;

   // --- First trade
   if(totalPositions == 0)
   {
      PeakPoints = 0.0;
      OpenTrade(trend, StartLot);
      LastDirection = trend;
      LastOpenPrice = (trend == 1)
         ? SymbolInfoDouble(TradeSymbol, SYMBOL_ASK)
         : SymbolInfoDouble(TradeSymbol, SYMBOL_BID);
      return;
   }

   // --- Grid logic (unchanged)
   double currentPrice = (LastDirection == 1)
      ? SymbolInfoDouble(TradeSymbol, SYMBOL_BID)
      : SymbolInfoDouble(TradeSymbol, SYMBOL_ASK);

   double diffPoints = (LastDirection == 1)
      ? (LastOpenPrice - currentPrice) / _Point
      : (currentPrice - LastOpenPrice) / _Point;

   if(diffPoints >= StepPoints && totalPositions < MaxTrades)
   {
      double nextLot = StartLot + (LotStep * totalPositions);
      OpenTrade(LastDirection, nextLot);
      LastOpenPrice = currentPrice;
   }

   // ===== BASKET PROFIT IN POINTS =====
   double basketPoints = GetBasketPoints(TradeSymbol);

   // Basket Stop Loss (points)
   if(basketPoints <= -MaxLossPoints)
   {
      Print("Basket SL hit (points). Closing all trades.");
      CloseAllPositionsForSymbol(TradeSymbol);
      PeakPoints = 0.0;
      return;
   }

   // VERY TIGHT Basket Profit Lock Logic
   if(basketPoints >= ProfitLockStartPoints)
   {
      // Update peak profit
      if(basketPoints > PeakPoints)
      {
         PeakPoints = basketPoints;
   
         // Lock profit tightly below peak
         LockedPoints = PeakPoints - TrailPoints;
   
         // Never allow lock below activation level
         if(LockedPoints < ProfitLockStartPoints)
            LockedPoints = ProfitLockStartPoints;
      }
   
      // Close basket on smallest meaningful reversal
      if(basketPoints <= LockedPoints)
      {
         Print("Tight basket profit lock hit. Closing all trades.");
         CloseAllPositionsForSymbol(TradeSymbol);
         PeakPoints   = 0.0;
         LockedPoints = 0.0;
         return;
      }
   }


}

//+------------------------------------------------------------------+
void OpenTrade(int direction, double lot)
{
   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action       = TRADE_ACTION_DEAL;
   request.symbol       = TradeSymbol;
   request.volume       = lot;
   request.deviation    = 20;
   request.type_filling = ORDER_FILLING_IOC;

   if(direction == 1)
   {
      request.type  = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(TradeSymbol, SYMBOL_ASK);
   }
   else
   {
      request.type  = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(TradeSymbol, SYMBOL_BID);
   }

   if(!OrderSend(request, result))
   {
      Print("OrderSend failed. Retcode=", result.retcode);
   }

}

//+------------------------------------------------------------------+
int CountPositionsForSymbol(string symbol)
{
   int cnt = 0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetString(POSITION_SYMBOL) == symbol)
         cnt++;
   }
   return cnt;
}


//+------------------------------------------------------------------+
//| Calculate basket profit in POINTS                                |
//+------------------------------------------------------------------+
double GetBasketPoints(string symbol)
{
   double totalPoints = 0.0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;

      int type = (int)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double volume = PositionGetDouble(POSITION_VOLUME);

      double price = (type == POSITION_TYPE_BUY)
         ? SymbolInfoDouble(symbol, SYMBOL_BID)
         : SymbolInfoDouble(symbol, SYMBOL_ASK);

      double points = (type == POSITION_TYPE_BUY)
         ? (price - openPrice) / _Point
         : (openPrice - price) / _Point;

      totalPoints += points * volume;
   }
   return totalPoints;
}

//+------------------------------------------------------------------+
void CloseAllPositionsForSymbol(string symbol)
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;

      trade.PositionClose(ticket);
   }
}
