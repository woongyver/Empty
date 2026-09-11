"""날짜 입력(문자열 / date / datetime)을 항상 'yyyymmdd' 문자열로 변환한다."""

from __future__ import annotations

import re
from datetime import date, datetime

__all__ = ["to_yyyymmdd"]

# 구분자(-, /, ., 공백)가 있는 형식과 구분자가 없는 8자리 형식을 함께 지원한다.
_SEPARATED = re.compile(r"^(\d{4})[-/.\s](\d{1,2})[-/.\s](\d{1,2})$")
_COMPACT = re.compile(r"^(\d{4})(\d{2})(\d{2})$")


def to_yyyymmdd(value: str | int | date | datetime | None) -> str:
    """년월일을 나타내는 값을 'yyyymmdd' 문자열로 변환한다.

    지원하는 입력:
        - datetime.date / datetime.datetime  -> 날짜 부분만 사용
        - 'yyyymmdd', 'yyyy-mm-dd', 'yyyy/m/d', 'yyyy.mm.dd', 'yyyy mm dd'
        - 위 형식 뒤에 시간이 붙은 문자열 ('2024-01-02 13:45:00', '2024-01-02T13:45:00')
        - int (예: 20240102)

    Raises:
        TypeError: 지원하지 않는 타입인 경우
        ValueError: 날짜로 해석할 수 없거나 실제로 존재하지 않는 날짜인 경우
    """
    if isinstance(value, datetime):
        return value.strftime("%Y%m%d")
    if isinstance(value, date):  # datetime 은 date 의 하위 클래스이므로 순서가 중요하다.
        return value.strftime("%Y%m%d")
    if isinstance(value, int) and not isinstance(value, bool):
        value = str(value)
    if not isinstance(value, str):
        raise TypeError(f"지원하지 않는 날짜 타입입니다: {type(value).__name__}")

    text = value.strip()
    if not text:
        raise ValueError("빈 문자열은 날짜로 변환할 수 없습니다.")

    # 시간 부분이 있으면 잘라낸다. ('2024-01-02T13:45:00', '2024-01-02 13:45:00')
    head = re.split(r"[T\s]", text, maxsplit=1)[0] if _has_time_part(text) else text

    match = _SEPARATED.match(head) or _COMPACT.match(head)
    if not match:
        raise ValueError(f"날짜 형식을 인식할 수 없습니다: {value!r}")

    year, month, day = (int(part) for part in match.groups())
    try:
        parsed = date(year, month, day)  # 2024-02-30 같은 값을 여기서 걸러낸다.
    except ValueError as exc:
        raise ValueError(f"존재하지 않는 날짜입니다: {value!r}") from exc
    return parsed.strftime("%Y%m%d")


def _has_time_part(text: str) -> bool:
    """'yyyy mm dd' 처럼 공백이 구분자인 경우와 시간이 붙은 경우를 구분한다."""
    if "T" in text or ":" in text:
        return True
    return bool(re.match(r"^\d{8}\s", text))


if __name__ == "__main__":
    samples = [
        "20240102",
        "2024-01-02",
        "2024/1/2",
        "2024.01.02",
        "2024 01 02",
        "2024-01-02 13:45:00",
        "2024-01-02T13:45:00",
        20240102,
        date(2024, 1, 2),
        datetime(2024, 1, 2, 13, 45),
    ]
    for sample in samples:
        print(f"{sample!r:<32} -> {to_yyyymmdd(sample)}")
