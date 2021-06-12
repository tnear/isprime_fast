% calculate (a * b) % m without overflowing uint64
% private function which does minimal input validation
% https://en.wikipedia.org/wiki/Modular_arithmetic#Example_implementations
function result = ModMultiply(a, b, m)
    % faster calculation for non-overflowing multiplication
    c = a * b;
    if c ~= uint64(18446744073709551615) % intmax("uint64")
        % does not overflow, use faster calculation
        result = mod(c, m);
        return;
    elseif a == b
        % Faster handling for special case of a*a (mod m)
        % a^2 (mod m) equivalent to (m - a)^2 mod m, so choose smaller
        assert(m > a);
        aSmall = min(m - a, a);

        if aSmall <= 4294967295
            % highest number squared which does not oveflow uint64
            result = mod(aSmall * aSmall, m);
            return;
        end
    elseif a == 2
        % faster calculation when a=2 (common in LucasPrime)
        result = b - (m - b);
        return;
    end

    assert(b ~= 2, 'a & b should be flipped');
    shift = bitshift(b, 0:-1:-63);
    oddIdx = find(mod(shift, 2) == 1);
    stopIdx = oddIdx(end);
    seqA = zeros(1, stopIdx, 'uint64');
    seqA(1) = a;
    for idx = 2 : stopIdx
        if seqA(idx-1) >= uint64(9223372036854775808) % intmax("uint64") / 2
            seqA(idx) = seqA(idx-1) - (m - seqA(idx-1)); % avoid overflow of a*2
        else
            seqA(idx) = mod(bitshift(seqA(idx-1), 1), m);
        end
    end

    result = sum(seqA(oddIdx), 'native');
    if result == uint64(18446744073709551615)
        % mod add when sum overflows
        result = 0;
        for idx = oddIdx % odd numbers
            result = ModAdd(result, seqA(idx), m);
        end
    else
        result = mod(result, m);
    end
end
