from pathlib import Path
p = Path(r'd:\TFG\RestEspe\frontendflutter\lib\data\services\menu_service.dart')
s = p.read_text(encoding='utf-8')
open_braces = 0
line_no = 0
issues = []
for line in s.splitlines():
    line_no += 1
    open_braces += line.count('{') - line.count('}')
    if open_braces < 0:
        issues.append(f'Unbalanced }} at line {line_no}')

print('Brace balance final delta:', open_braces)
if issues:
    print('Issues:')
    print('\n'.join(issues))
else:
    print('No immediate brace underflow issues.')

for name in ['eliminarPlato','actualizarPlato','eliminarSeccion','getCategorias','crearPlato','actualizarSeccion']:
    print(('FOUND' if name in s else 'MISSING'), name)
