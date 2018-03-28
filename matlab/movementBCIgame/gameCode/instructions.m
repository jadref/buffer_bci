% Create instructions for the movementBCI game
function [instruct]= instructions() 
instruct={'Welcome to our game,'
    ''
    'You will see an oval that grows bigger over time.'
    'The bigger the oval gets, the more points you can win!'
    'Whoever presses <space> first gets the'
    'current amount of points.'
    ''
    'Your goal is to beat the computer!'
    ''
    'Beware, the computer *learns* when you move and tries'
    'to press <space> just before you do!'
    ''
    'Press <space> to continue.'};
end