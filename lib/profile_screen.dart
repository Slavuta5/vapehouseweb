import 'package:flutter/material.dart';
import 'cart_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final latestOrder = CartManager.orders.isNotEmpty ? CartManager.orders.last : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Особистий кабінет', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Блок користувача
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF7B2CBF),
                  child: const Text('ІП', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Іван Петренко', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('+380 97 123 45 67', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Меню
            _buildMenuItem(Icons.location_on_outlined, 'Мої адреси', '2 адреси'),
            _buildMenuItem(Icons.receipt_long_outlined, 'Мої замовлення', 'Історія покупок'),
            _buildMenuItem(Icons.confirmation_number_outlined, 'Промокоди', 'Тут зберігаються ваші знижки'),
            _buildMenuItem(Icons.settings_outlined, 'Налаштування', 'Сповіщення, темна тема'),

            const SizedBox(height: 24),

            // Блок "Останнє замовлення" з таймлайном
            if (latestOrder != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Останнє замовлення #${latestOrder.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(latestOrder.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF7B2CBF).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildStatusStep('Прийнято', '14:32', true),
                    _buildStatusStep('Готуємо', '14:45', true),
                    _buildStatusStep('В дорозі', '15:10', latestOrder.status == 'В дорозі' || latestOrder.status == 'Доставлено'),
                    _buildStatusStep('Доставлено', 'Очікується', latestOrder.status == 'Доставлено'),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B2CBF), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, String time, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF7B2CBF) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: isDone ? Colors.white : Colors.grey, fontWeight: isDone ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}