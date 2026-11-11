const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../lib/screens');
function visit(dir) {
  for (const entry of fs.readdirSync(dir, {withFileTypes:true})) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) { visit(file); continue; }
    if (!file.endsWith('.dart')) continue;
    const original = fs.readFileSync(file, 'utf8');
    let source = original.replace(/const EdgeInsets.fromLTRB\((\d+), (\d+), \d+, (?:110|120|AppDimens.navBarScrollPadding)\)/g,
      'AppInsets.scrollPadding(context, horizontal: $1, top: $2)');
    source = source.replace(/const SizedBox\(height: AppDimens.navBarScrollPadding\)/g,
      'SizedBox(height: AppInsets.bottomBarClearance(context))');
    if (source !== original) {
      if (!source.includes("import 'package:food_fight/core/utils/app_insets.dart';"))
        source = "import 'package:food_fight/core/utils/app_insets.dart';\n" + source;
      fs.writeFileSync(file, source);
    }
  }
}
visit(root);
