// import 'package:flutter/material.dart';
//
// class DashboardPage extends StatefulWidget {
//   const DashboardPage({Key? key}) : super(key: key);
//
//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }
//
// class _DashboardPageState extends State<DashboardPage> {
//   int _selectedIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Row(
//         children: [
//           // Navigation Sidebar
//           _buildSidebar(),
//
//           // Main Content
//           Expanded(
//             child: _buildMainContent(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSidebar() {
//     return Container(
//       width: 250,
//       color: Colors.white,
//       child: Column(
//         children: [
//           // Logo and App Title
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 24),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF28A745).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(
//                     Icons.shield,
//                     color: Color(0xFF28A745),
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Crop Compliance',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF28A745),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(),
//
//           // Navigation Items
//           _buildNavItem(0, 'Dashboard', Icons.dashboard_rounded),
//           _buildNavItem(1, 'Compliance Tracker', Icons.trending_up),
//           _buildNavItem(2, 'Compliance Report', Icons.description),
//           _buildNavItem(3, 'Audit Index', Icons.assignment_turned_in),
//           const Divider(),
//           _buildNavItem(4, 'Settings', Icons.settings),
//           _buildNavItem(5, 'Profile', Icons.person),
//
//           const Spacer(),
//
//           // Logout Button
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: OutlinedButton.icon(
//               onPressed: () {},
//               icon: const Icon(Icons.logout, size: 18),
//               label: const Text('Logout'),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: Colors.grey[700],
//                 minimumSize: const Size(double.infinity, 44),
//                 side: BorderSide(color: Colors.grey[300]!),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(int index, String title, IconData icon) {
//     bool isSelected = _selectedIndex == index;
//
//     return InkWell(
//       onTap: () {
//         setState(() {
//           _selectedIndex = index;
//         });
//       },
//       child: Container(
//         height: 56,
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF28A745).withOpacity(0.1) : null,
//           border: isSelected
//               ? const Border(
//             left: BorderSide(
//               color: Color(0xFF28A745),
//               width: 4,
//             ),
//           )
//               : null,
//         ),
//         padding: EdgeInsets.only(
//           left: isSelected ? 21 : 25, // Offset for the border
//           right: 25,
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? const Color(0xFF28A745) : Colors.grey[600],
//               size: 20,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               title,
//               style: TextStyle(
//                 color: isSelected ? const Color(0xFF28A745) : Colors.grey[800],
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMainContent() {
//     // Displaying the main dashboard content
//     return Container(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Dashboard Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Farm Compliance Dashboard',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF333333),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Welcome back, Farm Manager',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//               // Action buttons
//               Row(
//                 children: [
//                   IconButton(
//                     onPressed: () {},
//                     icon: const Icon(Icons.notifications_outlined),
//                     tooltip: 'Notifications',
//                   ),
//                   const SizedBox(width: 8),
//                   CircleAvatar(
//                     radius: 18,
//                     backgroundColor: const Color(0xFF28A745),
//                     child: Text(
//                       'FM',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 32),
//
//           // Dashboard Cards
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: 3,
//               crossAxisSpacing: 24,
//               mainAxisSpacing: 24,
//               childAspectRatio: 1.2,
//               children: [
//                 // Compliance Tracker Card
//                 _buildComplianceTrackerCard(),
//
//                 // Compliance Report Card
//                 _buildCardWithIconAndText(
//                   'Compliance Report',
//                   'Get a clear overview of important documents, their expiry dates, and statuses, with an option to upload updated files directly into the system.',
//                   Icons.description,
//                   Colors.purple,
//                 ),
//
//                 // Audit Index Card
//                 _buildCardWithIconAndText(
//                   'Audit Index',
//                   'Store and organize your documents here, making it quick for you to upload or find files that are connected to your compliance.',
//                   Icons.assignment_turned_in,
//                   Colors.blue,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildComplianceTrackerCard() {
//     double compliancePercentage = 0.78; // 78%
//
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//         onTap: () {
//           // Navigate to Compliance Tracker
//         },
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF28A745).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.trending_up,
//                       color: Color(0xFF28A745),
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   const Expanded(
//                     child: Text(
//                       'Compliance Tracker',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'See your current compliance progress making it simple and easily to access and update documents that are overdue, coming up, or expired to stay on track.',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF666666),
//                 ),
//               ),
//               const Spacer(),
//               const Text(
//                 'Overall Compliance',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(4),
//                       child: LinearProgressIndicator(
//                         value: compliancePercentage,
//                         backgroundColor: Colors.grey[200],
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                           Color(0xFF28A745),
//                         ),
//                         minHeight: 8,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     '${(compliancePercentage * 100).toInt()}%',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF28A745),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCardWithIconAndText(String title, String description, IconData icon, Color color) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: InkWell(
//         onTap: () {
//           // Navigate to respective screen
//         },
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: color.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Icon(
//                       icon,
//                       color: color,
//                       size: 24,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 description,
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Color(0xFF666666),
//                 ),
//               ),
//               const Spacer(),
//               Align(
//                 alignment: Alignment.bottomRight,
//                 child: Icon(
//                   Icons.arrow_forward,
//                   color: color,
//                   size: 20,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }