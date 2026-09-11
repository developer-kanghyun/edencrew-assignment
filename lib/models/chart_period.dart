/// 상세 화면의 기간 탭.
///
/// [tradingDays]는 그 기간의 대략적인 거래일 수다. 일별 시세는 한 페이지에
/// 10거래일이 들어오므로, 이 값이 몇 페이지를 받아야 하는지를 정한다.
enum ChartPeriod {
  oneMonth('1개월', 20),
  threeMonths('3개월', 60),
  sixMonths('6개월', 120),
  oneYear('1년', 245);

  const ChartPeriod(this.label, this.tradingDays);

  final String label;
  final int tradingDays;

  static const int daysPerPage = 10;

  /// 이 기간을 채우는 데 필요한 페이지 수.
  int get requiredPages => (tradingDays / daysPerPage).ceil();
}
