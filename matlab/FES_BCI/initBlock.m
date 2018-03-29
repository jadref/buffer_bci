function block_msg=initBlock(msgh, b, nr_blocks, correct_time)
block_msg=set(msgh,'string',{'Time for a short break...' 
    ''
    '' 
    sprintf('This was block %1g out of %1g', b, nr_blocks)
    ''
    ''
    sprintf('You got %1g trials correct this block!', correct_time)
    ''
    ''
    'Press 4 when you are ready to continue...'}, 'color',[1 1 1], 'visible', 'on'); drawnow;
end
      