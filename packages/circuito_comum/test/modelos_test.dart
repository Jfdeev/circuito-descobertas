import 'package:circuito_comum/circuito_comum.dart';
import 'package:flutter_test/flutter_test.dart';

const _ativoA = Estande(
  id: 'a',
  nome: 'A',
  descricao: 'd',
  localizacao: 'l',
  ativo: true,
);
const _ativoB = Estande(
  id: 'b',
  nome: 'B',
  descricao: 'd',
  localizacao: 'l',
  ativo: true,
);
const _inativoC = Estande(
  id: 'c',
  nome: 'C',
  descricao: 'd',
  localizacao: 'l',
  ativo: false,
);

void main() {
  group('Estande', () {
    test('converte para mapa e volta sem perdas', () {
      final copia = Estande.fromMap(_ativoA.id, _ativoA.toMap());
      expect(copia, _ativoA);
    });

    test('usa valores seguros para campos ausentes', () {
      final e = Estande.fromMap('x', {});
      expect(e.nome, '');
      expect(e.ativo, isFalse);
    });

    test('copyWith altera apenas o informado', () {
      final e = _ativoA.copyWith(ativo: false);
      expect(e.ativo, isFalse);
      expect(e.nome, _ativoA.nome);
      expect(e.id, _ativoA.id);
    });
  });

  group('QrEstande', () {
    test('codifica e decodifica o mesmo ID', () {
      expect(QrEstande.decodificar(QrEstande.codificar('Ab12-x')), 'Ab12-x');
    });

    test('ignora espaços nas bordas', () {
      expect(QrEstande.decodificar('  ${QrEstande.prefixo}abc \n'), 'abc');
    });

    test('rejeita conteúdo de outro QR', () {
      expect(QrEstande.decodificar('https://exemplo.com'), isNull);
      expect(QrEstande.decodificar(null), isNull);
      expect(QrEstande.decodificar(''), isNull);
    });

    test('rejeita ID vazio ou com caracteres inválidos', () {
      expect(QrEstande.decodificar(QrEstande.prefixo), isNull);
      expect(QrEstande.decodificar('${QrEstande.prefixo}a_b'), isNull);
      expect(QrEstande.decodificar('${QrEstande.prefixo}a/b'), isNull);
    });

    test('não gera QR para ID inválido', () {
      expect(() => QrEstande.codificar('a_b'), throwsArgumentError);
    });
  });

  group('ConfigMissao', () {
    test('padrão local é a missão desligada', () {
      expect(ConfigMissao.desligada.ativa, isFalse);
      expect(ConfigMissao.desligada.estandeIds, isEmpty);
    });

    test('interpreta lista de IDs com separadores variados', () {
      final c = ConfigMissao.fromValores(ativa: true, estandes: ' a, b;c\n a ,');
      expect(c.estandeIds, {'a', 'b', 'c'});
    });

    test('participantes considera só estandes ativos selecionados', () {
      final c = ConfigMissao.fromValores(ativa: true, estandes: 'a,c,zzz');
      expect(c.participantes([_ativoA, _ativoB, _inativoC]), [_ativoA]);
      expect(c.visivel([_ativoA, _ativoB, _inativoC]), isTrue);
    });

    test('missão desligada não tem participantes nem chamada', () {
      final c = ConfigMissao.fromValores(ativa: false, estandes: 'a,b');
      expect(c.participantes([_ativoA, _ativoB]), isEmpty);
      expect(c.visivel([_ativoA, _ativoB]), isFalse);
    });

    test('missão ligada sem estandes ativos não aparece', () {
      final c = ConfigMissao.fromValores(ativa: true, estandes: 'c');
      expect(c.visivel([_inativoC]), isFalse);
    });

    test('igualdade ignora a ordem dos IDs', () {
      expect(
        ConfigMissao.fromValores(ativa: true, estandes: 'a,b'),
        ConfigMissao.fromValores(ativa: true, estandes: 'b,a'),
      );
    });
  });

  group('check-in', () {
    test('chave composta junta visitante e estande', () {
      expect(chaveCheckin('uid1', 'est1'), 'uid1_est1');
    });

    test('totalPorEstande conta registros por estande', () {
      expect(totalPorEstande(['a', 'b', 'a']), {'a': 2, 'b': 1});
      expect(totalPorEstande([]), isEmpty);
    });
  });
}
