// Testes das regras do Firestore no emulador: npm run test:rules
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const ADMIN = 'admin1';
const VISITANTE = 'visitante1';
const OUTRO = 'visitante2';

const estande = (ativo = true) => ({
  nome: 'Robótica',
  descricao: 'Robôs',
  localizacao: 'Corredor A',
  ativo,
});

const checkin = (visitanteId, estandeId) => ({
  visitanteId,
  estandeId,
  criadoEm: serverTimestamp(),
});

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-circuito',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'admins', ADMIN), { email: 'adm@feira.com' });
    await setDoc(doc(db, 'estandes', 'ativo'), estande(true));
    await setDoc(doc(db, 'estandes', 'inativo'), estande(false));
    await setDoc(doc(db, 'checkins', `${OUTRO}_ativo`), {
      visitanteId: OUTRO,
      estandeId: 'ativo',
      criadoEm: new Date(),
    });
  });
});

const admin = () => env.authenticatedContext(ADMIN).firestore();
const visitante = () => env.authenticatedContext(VISITANTE).firestore();
const anonimoSemLogin = () => env.unauthenticatedContext().firestore();

describe('estandes', () => {
  test('somente admin cria e edita', async () => {
    await assertSucceeds(setDoc(doc(admin(), 'estandes', 'novo'), estande()));
    await assertSucceeds(updateDoc(doc(admin(), 'estandes', 'ativo'), { ativo: false }));
    await assertFails(setDoc(doc(visitante(), 'estandes', 'novo2'), estande()));
    await assertFails(updateDoc(doc(visitante(), 'estandes', 'ativo'), { ativo: false }));
    await assertFails(deleteDoc(doc(visitante(), 'estandes', 'ativo')));
  });

  test('admin não grava campos fora do esquema', async () => {
    await assertFails(
      setDoc(doc(admin(), 'estandes', 'x'), { ...estande(), extra: 1 }),
    );
    await assertFails(setDoc(doc(admin(), 'estandes', 'x'), { ...estande(), nome: '' }));
  });

  test('visitante lista apenas ativos', async () => {
    const col = collection(visitante(), 'estandes');
    await assertSucceeds(getDocs(query(col, where('ativo', '==', true))));
    await assertFails(getDocs(col));
    await assertSucceeds(getDocs(collection(admin(), 'estandes')));
  });

  test('visitante lê um estande pelo ID para validar o QR', async () => {
    await assertSucceeds(getDoc(doc(visitante(), 'estandes', 'inativo')));
    await assertSucceeds(getDoc(doc(visitante(), 'estandes', 'inexistente')));
  });

  test('sem login não lê nada', async () => {
    await assertFails(getDoc(doc(anonimoSemLogin(), 'estandes', 'ativo')));
  });
});

describe('checkins', () => {
  test('visitante cria o próprio check-in em estande ativo', async () => {
    await assertSucceeds(
      setDoc(doc(visitante(), 'checkins', `${VISITANTE}_ativo`), checkin(VISITANTE, 'ativo')),
    );
  });

  test('recusa estande inativo ou inexistente', async () => {
    await assertFails(
      setDoc(doc(visitante(), 'checkins', `${VISITANTE}_inativo`), checkin(VISITANTE, 'inativo')),
    );
    await assertFails(
      setDoc(doc(visitante(), 'checkins', `${VISITANTE}_nada`), checkin(VISITANTE, 'nada')),
    );
  });

  test('recusa identidade alheia ou chave fora do padrão', async () => {
    await assertFails(
      setDoc(doc(visitante(), 'checkins', `${OUTRO}_ativo2`), checkin(OUTRO, 'ativo')),
    );
    await assertFails(
      setDoc(doc(visitante(), 'checkins', 'qualquer'), checkin(VISITANTE, 'ativo')),
    );
  });

  test('recusa data do cliente e campos extras', async () => {
    await assertFails(
      setDoc(doc(visitante(), 'checkins', `${VISITANTE}_ativo`), {
        visitanteId: VISITANTE,
        estandeId: 'ativo',
        criadoEm: new Date(),
      }),
    );
    await assertFails(
      setDoc(doc(visitante(), 'checkins', `${VISITANTE}_ativo`), {
        ...checkin(VISITANTE, 'ativo'),
        pontos: 100,
      }),
    );
  });

  test('não permite duplicar, alterar ou apagar', async () => {
    const ref = doc(visitante(), 'checkins', `${VISITANTE}_ativo`);
    await assertSucceeds(setDoc(ref, checkin(VISITANTE, 'ativo')));
    await assertFails(setDoc(ref, checkin(VISITANTE, 'ativo')));
    await assertFails(deleteDoc(ref));
  });

  test('visitante consulta só o próprio check-in, inclusive inexistente', async () => {
    await assertSucceeds(getDoc(doc(visitante(), 'checkins', `${VISITANTE}_ativo`)));
    await assertFails(getDoc(doc(visitante(), 'checkins', `${OUTRO}_ativo`)));
    await assertFails(getDocs(collection(visitante(), 'checkins')));
  });

  test('organização consulta todos os registros', async () => {
    await assertSucceeds(getDocs(collection(admin(), 'checkins')));
  });
});

describe('admins', () => {
  test('cada um lê só o próprio documento e ninguém grava', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'admins', ADMIN)));
    await assertSucceeds(getDoc(doc(visitante(), 'admins', VISITANTE)));
    await assertFails(getDoc(doc(visitante(), 'admins', ADMIN)));
    await assertFails(setDoc(doc(visitante(), 'admins', VISITANTE), {}));
  });
});
