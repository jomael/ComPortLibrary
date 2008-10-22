unit CportTimerUtils;
{$Q-} // Range/Overflow Checking Off. Don't remove this line unless you like bogus exceptions halting your application.

{ Using Windows API Timer Tick Function GetTickCount,
   and these
  two utility functions, you have a general timer
  system.

  Example:
      var
        X1,X2,L:DWORD;
      begin
        // at point when you want to begin counting elapsed time:
        X1 := GetTickCount
        ... time passes ...
        // later, at point when you want to know how many ticks/milliseconds have elapsed
        X2 := GetTickCount
        L := TimerElapsed(X1,X2);

        // To set a timer that "fires" at a particular time in the future, do this:

        X1 := GetTickCount+1000; // One second in the future.
        // now, do a while loop until setpoint expires:
        if TimerHasReachedSetpoint(X1,GetTimerTick) then ...

}


interface

uses Types;

// Return elapsed ticks between tick1 and tick2.
function TimerElapsed(tick1,tick2:DWORD):DWORD;

// Returns True if systemTick (a current reading from GetTickCount has
// gone past the timer tick setpoint in timerTick)
function TimerHasReachedSetpoint(systemTick,timerTick:DWORD):Boolean;



implementation
// Return elapsed ticks between tick1 and tick2.
function TimerElapsed(tick1,tick2:DWORD):DWORD;
begin
  if ((tick2-tick1) < $80000000) then { timer roll-over check }
      result := (tick2 - tick1) { normal }
  else
      result := (not tick1)+tick2; {rollover calculation}
end;



function TimerHasReachedSetpoint(systemTick,timerTick:DWORD):Boolean;
var
  ElapsedMS : DWORD;
begin
  ElapsedMS := TimerElapsed(timerTick,systemTick);
  if ((ElapsedMS>0) and (ElapsedMS < $80000000)) then
      result := true
  else
      result := false;
end;



end.
