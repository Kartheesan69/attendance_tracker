Widget _buildDrawer() {
  return Scaffold(
    body: Center(
      child: Text('Main Content'),
    ),
    endDrawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 200, // Set the desired height for the header
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Use primary color for the header
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Options',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: "SanFrancisco",
                      color: Colors.white, // Text color for the header
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('Add Course'),
            onTap: () {
              Navigator.pop(context);
              _addCourse();
            },
          ),
          ListTile(
            title: Text('Set Timetable'),
            onTap: () {
              Navigator.pop(context);
              _setTimetable();
            },
          ),
          ListTile(
            title: Text('Show Timetable'),
            onTap: () {
              Navigator.pop(context);
              _showTimetable();
            },
          ),
          // Add more ListTiles for additional menu items
          ListTile(
            title: Text('Item 3'),
            onTap: () {
              // Handle the item 3 action
            },
          ),
          // ... Add more ListTiles as needed ...
        ],
      ),
    ),
  );
}
