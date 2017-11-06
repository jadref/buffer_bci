function pressureweight = pressurepoints(timetogo,trialduration)

if timetogo > trialduration/2
    pressureweight = 1;
else
    pressureweight = 2*timetogo/trialduration;
end

end