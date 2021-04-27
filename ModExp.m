function result = ModExp(base, exp, m)
    % Modular exponentiation (powermod)
    % result = base ^ exp (mod m)
    % private function which does minimal input validation
    if m == 0
        result = base ^ exp;
        return;
    end

    origCls = class(base);
    if base < 0
        % make base positive by adding multiple of m
        multiple = floor(-base / m) + 1;
        base = base + multiple * m;
        assert(base >= 0);
    end

    base = uint64(base);
    exp = uint64(exp);
    m = uint64(m);

    if exp == 2 && base <= 4294967295
        % squaring is common enough to special case
        % 4294967295 is max number which does not overflow uint64 when squared
        result = mod(base * base, m);
        return;
    end

    result = 1;
    base = mod(base, m);

    % exponentiation by squaring
    while exp > 0
        if bitand(exp, 1) % odd numbers
            result = ModMultiply(result, base, m);
        end

        base = ModMultiply(base, base, m);
        exp = bitshift(exp, -1);
    end

    result = cast(result, origCls);
end
