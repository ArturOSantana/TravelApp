import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WaterfallChartWidget extends StatelessWidget {
  final double initialBudget;
  final Map<String, double> categories;
  final String title;

  const WaterfallChartWidget({
    super.key,
    required this.initialBudget,
    required this.categories,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    double runningTotal = initialBudget;
    final List<WaterfallItem> items = [
      WaterfallItem(
        label: 'Orçamento Inicial',
        value: initialBudget,
        isStart: true,
        runningTotal: runningTotal,
      ),
    ];

    categories.forEach((category, amount) {
      runningTotal -= amount;
      items.add(WaterfallItem(
        label: category,
        value: -amount,
        isStart: false,
        runningTotal: runningTotal,
      ));
    });

    items.add(WaterfallItem(
      label: 'Saldo Final',
      value: runningTotal,
      isEnd: true,
      runningTotal: runningTotal,
    ));

    final maxValue = initialBudget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final previousTotal =
                    index > 0 ? items[index - 1].runningTotal : initialBudget;

                return _buildWaterfallBar(
                  context,
                  item,
                  previousTotal,
                  maxValue,
                  currencyFormat,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallBar(
    BuildContext context,
    WaterfallItem item,
    double previousTotal,
    double maxValue,
    NumberFormat currencyFormat,
  ) {
    final barWidth = 80.0;
    final spacing = 20.0;

    Color barColor;
    if (item.isStart) {
      barColor = Colors.blue;
    } else if (item.isEnd) {
      barColor = item.value >= 0 ? Colors.green : Colors.red;
    } else {
      barColor = Colors.orange;
    }

    return Container(
      width: barWidth + spacing,
      padding: EdgeInsets.only(right: spacing),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Linha conectora
                if (!item.isStart)
                  Positioned(
                    left: -spacing,
                    top: (1 - previousTotal / maxValue) * 250,
                    child: Container(
                      width: spacing,
                      height: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3),
                    ),
                  ),
                // Barra
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: spacing,
                  child: Column(
                    children: [
                      if (!item.isStart && !item.isEnd)
                        Container(
                          height: ((previousTotal - item.runningTotal) /
                                  maxValue *
                                  250)
                              .abs(),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      else
                        Container(
                          height: (item.runningTotal / maxValue * 250).abs(),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                ),
                // Valor no topo
                Positioned(
                  top: item.isStart || item.isEnd
                      ? (1 - item.runningTotal / maxValue) * 250 - 30
                      : (1 - previousTotal / maxValue) * 250 - 30,
                  left: 0,
                  right: spacing,
                  child: Text(
                    currencyFormat.format(item.value.abs()),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: barWidth,
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class WaterfallItem {
  final String label;
  final double value;
  final bool isStart;
  final bool isEnd;
  final double runningTotal;

  WaterfallItem({
    required this.label,
    required this.value,
    this.isStart = false,
    this.isEnd = false,
    required this.runningTotal,
  });
}

