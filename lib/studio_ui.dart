part of 'main.dart';

extension StudioUi on _StudioState {
  Widget buildScreen() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const Text('Autosave on',
                style: TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: undoStack.isEmpty ? null : undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: redoStack.isEmpty ? null : redo,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open',
            onPressed: openNamed,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: saveNamed,
          ),
          PopupMenuButton<String>(
            onSelected: menuAction,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New drawing')),
              PopupMenuItem(value: 'rename', child: Text('Rename project')),
              PopupMenuItem(value: 'fit', child: Text('Zoom to fit')),
              PopupMenuItem(value: 'grid', child: Text('Toggle grid')),
              PopupMenuItem(value: 'snap', child: Text('Toggle snap')),
              PopupMenuItem(value: 'unit', child: Text('Change units')),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, box) {
        canvasSize = box.biggest;
        return Listener(
          onPointerDown: pDown,
          onPointerMove: pMove,
          onPointerUp: pUp,
          onPointerCancel: pUp,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: scaleStart,
            onScaleUpdate: scaleUpdate,
            onScaleEnd: scaleEnd,
            onTapUp: (d) => tapAt(d.localPosition),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: PlanPainter(
                      doc: doc,
                      view: view,
                      selWall: selWall,
                      selRoom: selRoom,
                      draftA: draftA,
                      draftB: draftB,
                      draftIsRoom: tool == Tool.room,
                      gridOn: gridOn,
                    ),
                  ),
                ),
                hint(),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [statusBar(), toolBar()],
        ),
      ),
    );
  }

  Widget hint() {
    if (doc.walls.isNotEmpty || doc.rooms.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return const IgnorePointer(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Choose Wall and drag to draw.\n'
            'Use Length to type an exact size and angle.\n'
            'Choose Room and drag to draw a room with real area.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget statusBar() {
    final c = cursor;
    final xy = c == null
        ? 'Move pointer to read coordinates'
        : 'X ${formatLength(c.dx, doc.unit)}   Y ${formatLength(-c.dy, doc.unit)}';
    final snapLabel = snapOn ? 'Snap 50 mm' : 'Snap off';
    return Container(
      color: kPanel,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(xy,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ),
          Text('${toolName(tool)} · ${unitName(doc.unit)} · $snapLabel',
              style: const TextStyle(fontSize: 12, color: kAmber)),
        ],
      ),
    );
  }

  Widget toolBar() {
    return Container(
      color: kPanel,
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        children: [
          toolBtn(Icons.near_me, 'Select', tool == Tool.select,
              () => setTool(Tool.select)),
          toolBtn(Icons.vertical_split, 'Wall', tool == Tool.wall,
              () => setTool(Tool.wall)),
          toolBtn(Icons.crop_free, 'Room', tool == Tool.room,
              () => setTool(Tool.room)),
          toolBtn(Icons.pan_tool_outlined, 'Pan', tool == Tool.pan,
              () => setTool(Tool.pan)),
          toolBtn(Icons.straighten, 'Length', false, typedWall),
          toolBtn(Icons.edit_outlined, 'Edit', false, editSelected),
          toolBtn(Icons.delete_outline, 'Delete', false, deleteSelected),
          toolBtn(Icons.grid_on, 'Grid', gridOn, () {
            setState(() {
              gridOn = !gridOn;
            });
          }),
        ],
      ),
    );
  }

  Widget toolBtn(IconData icon, String label, bool on, VoidCallback onTap) {
    final col = on ? kAmber : Colors.white70;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: col, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: col)),
          ],
        ),
      ),
    );
  }

  String toolName(Tool t) => switch (t) {
        Tool.select => 'Select',
        Tool.wall => 'Wall',
        Tool.room => 'Room',
        Tool.pan => 'Pan',
      };
}
