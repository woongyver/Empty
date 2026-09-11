"""to_yyyymmdd 동작 확인용 테스트 (pytest 또는 `python3 test_to_yyyymmdd.py` 로 실행)."""

from datetime import date, datetime

import pytest

from to_yyyymmdd import to_yyyymmdd


@pytest.mark.parametrize(
    "value",
    [
        "20240102",
        "2024-01-02",
        "2024-1-2",
        "2024/01/02",
        "2024/1/2",
        "2024.01.02",
        "2024 01 02",
        "  2024-01-02  ",
        "2024-01-02 13:45:00",
        "2024-01-02T13:45:00",
        "20240102 13:45:00",
        20240102,
        date(2024, 1, 2),
        datetime(2024, 1, 2, 13, 45, 59),
    ],
)
def test_다양한_입력이_같은_문자열로_변환된다(value):
    assert to_yyyymmdd(value) == "20240102"


@pytest.mark.parametrize("value", ["", "   ", "2024-13-01", "2024-02-30", "24-01-02", "abcd", "2024010"])
def test_잘못된_값은_ValueError(value):
    with pytest.raises(ValueError):
        to_yyyymmdd(value)


@pytest.mark.parametrize("value", [None, 3.14, ["2024-01-02"], True])
def test_지원하지_않는_타입은_TypeError(value):
    with pytest.raises(TypeError):
        to_yyyymmdd(value)


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
