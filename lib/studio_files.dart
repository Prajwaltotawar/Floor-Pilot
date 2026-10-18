part of 'main.dart';

extension StudioFiles on _StudioState {
  void menuAction(String v) {
    switch (v) {
      case 'new':
        newProject();
        break;
      case 'rename':
        renameProject();
        break;
      case 'fit':
        fitView();
        break;
      case 'grid':
        setState(() {
          gridOn = !gridOn;
        });
        break;
      case 'snap':
        setState(() {
          snapOn = !snapOn;
        });
        break;
      case 'unit':
        setState(() {
          doc.unit = nextUnit(doc.unit);
        });
        scheduleSave();
        break;
    }
  }

  Future<void> newProject() async {
    final ok = await confirm('Start a new drawing? You can still undo this.');
    if (!ok) return;
    pushUndo();
    setState(() {
      doc = Doc();
      clearSelection();
      draftA = null;
      draftB = null;
    });
    scheduleSave();
    fitView();
  }

  Future<void> renameProject() async {
    final r = await askFields('Project name', ['Name'], [doc.name]);
    if (r == null || r[0].trim().isEmpty) return;
    setState(() {
      doc.name = r[0].trim();
    });
    scheduleSave();
  }

  Future<void> saveNamed() async {
    final r = await askFields('Save project', ['Project name'], [doc.name]);
    if (r == null) return;
    final name = r[0].trim();
    if (name.isEmpty) {
      toast('Enter a project name');
      return;
    }
    setState(() {
      doc.name = name;
    });
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('projects') ?? <String>[];
    if (!list.contains(name)) list.add(name);
    await prefs.setStringList('projects', list);
    await prefs.setString('proj_$name', doc.encode());
    toast('Saved "$name"');
  }

  Future<void> openNamed() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('projects') ?? <String>[];
    if (!mounted) return;
    if (list.isEmpty) {
      toast('No saved projects yet. Use Save first.');
      return;
    }
    final pick = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Open project'),
        children: [
          for (final n in list)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, n),
              child: Text(n),
            ),
        ],
      ),
    );
    if (pick == null) return;
    final text = prefs.getString('proj_$pick');
    if (text == null) {
      toast('Project not found');
      return;
    }
    try {
      final d = Doc.decode(text);
      pushUndo();
      setState(() {
        doc = d;
        clearSelection();
        draftA = null;
        draftB = null;
      });
      fitView();
      scheduleSave();
    } catch (e) {
      toast('Could not open this project: $e');
    }
  }
}
