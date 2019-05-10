% Determine whether human or computer won in this round.
function [winner]=compare_score(score,msgh)
    if score(1)>score(2)
        set(msgh, 'string',{'Congratulations you win! Your total score is:' '' sprintf(' you=%3g    comp=%3g', score) ''...
            sprintf('This was round %1g', i)}, 'Color',[1 1 1]);
        winner= human;
    elseif score(1)==score(2)
        set(msgh, 'string',{'It is a draw! Your total score is:' '' sprintf(' you=%3g    comp=%3g', score) ''...
            sprintf('This was round %1g', i)},'Color', [1 1 1]);
        winner=draw;
    else
        set(msgh, 'string',{'Too bad, you lost... Your total score is:' '' sprintf(' you=%3g    comp=%3g', score) ''...
            sprintf('This was round %1g', i)},'Color', [1 1 1]);
        winner =computer;
    end
end

