% calculate (a + b) % m without overflowing
% private function which does no input validation
function result = ModAdd(a, b, m)
    c = a + b;
    if c == uint64(18446744073709551615) % intmax("uint64")
        % avoid overflow of a + b
        %assert(m >= b);
        %assert(a + b > m)
        result = a - (m - b);
    else
        result = mod(c, m);
    end
end
