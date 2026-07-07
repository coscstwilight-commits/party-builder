<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ポケモン チーム構築支援</title>
  <style>
    body { font-family: 'Segoe UI', sans-serif; margin:20px; background:#f8fafc; }
    h1 { text-align:center; }
    table { width:100%; border-collapse:collapse; background:white; box-shadow:0 4px 12px rgba(0,0,0,0.1); }
    th, td { border:1px solid #ddd; padding:9px; text-align:center; }
    th { background:#1e40af; color:white; position:sticky; top:0; }
    .rank { width:60px; background:#f1f5f9; font-weight:bold; }
    .pokemon { width:180px; text-align:left; }
    .check-col { width:90px; }
    .candidate-col { min-width:130px; background:#f0f9ff; }
    .good { background:#bbf7d0 !important; font-weight:bold; }
    button { padding:9px 16px; margin:5px; border:none; border-radius:6px; cursor:pointer; }
    .primary { background:#2563eb; color:white; }
    .delete { background:#ef4444; color:white; }
    .edit { background:#eab308; color:black; }
  </style>
</head>
<body>
  <h1>ポケモン チーム構築支援</h1>

  <h2>ランキング更新（必要時）</h2>
  <textarea id="rankingInput" style="width:100%; height:120px;"></textarea><br>
  <button class="primary" onclick="updateRanking()">ランキング更新</button>

  <h2>候補の相性チェック</h2>
  <input type="text" id="candName" placeholder="候補名" style="width:320px;">
  <button class="primary" onclick="saveCandidate()">💾 保存</button>
  <button class="edit" onclick="overwriteSelected()">✏️ 選択中を上書き</button>
  <button class="delete" onclick="deleteSelected()">🗑 選択中を削除</button>
  <button onclick="clearCurrent()">クリア</button>

  <table id="checkTable">
    <thead>
      <tr>
        <th class="rank">順位</th>
        <th class="pokemon">上位ポケモン</th>
        <th class="check-col">対応</th>
      </tr>
    </thead>
    <tbody></tbody>
  </table>

  <h2>保存済み候補（Ctrl+クリックで複数選択）</h2>
  <select id="candidateSelect" multiple size="10" style="width:100%; max-width:900px;"></select><br>
  <button class="primary" onclick="showComparison()" style="padding:12px 30px;">横並び比較</button>

  <table id="compareTable" style="display:none; margin-top:20px;">
    <thead><tr id="compareHeader"></tr></thead>
    <tbody id="compareBody"></tbody>
  </table>

  <script>
    let upperList = [];
    let currentChecks = [];

    const defaultRanking = `ガブリアス
ミミッキュ
マスカーニャ
メタグロス
ブリジュラス
カバルドン
リザードン
ライチュウ
キュウコン (アローラ)
バシャーモ
サザンドラ
アーマーガア
アシレーヌ
ムクホーク
ギャラドス
マフォクシー
イダイトウ (オス)
キラフロル
ラグラージ
ウォッシュロトム
ゲッコウガ
カイリュー
オーロンゲ
ラウドボーン
クチート
サーフゴー
ペリッパー
ドドゲザン
ゲンガー
ギルガルド
ドラミドロ
ドラパルト
ハッサム
ダイケンキ (ヒスイ)
ウルガモス
ソウブレイズ
スターミー
ミミロップ
ブラッキー
バイバニラ
メガニウム
フシギバナ
オオニューラ
ルカリオ
カメックス
コノヨザル
ハラバリー
ニンフィア
ドヒドイデ
バンギラス
ドリュウズ
エルフーン
マンムー
ピクシー
ヒートロトム
マリルリ
ゾロアーク (ヒスイ)
ミロカロス
クエスパトラ
フラエッテ:永遠
ユキメノコ
カビゴン
メタモン
オニシズクモ
エアームド
サーナイト
ヤバソチャ
ジュカイン
スコヴィラン
ガルーラ
ヤミラミ
ジャローダ
イッカネズミ
ガオガエン
バサギリ
エルレイド
シビルドン
グレンアルマ
ヤドラン
ペンドラー`;

    function loadRanking() {
      const saved = localStorage.getItem('customRanking');
      upperList = (saved || defaultRanking).trim().split('\n').map(s => s.trim()).filter(Boolean);
      currentChecks = new Array(upperList.length).fill(false);
    }

    function renderCheckTable() {
      const tbody = document.querySelector('#checkTable tbody');
      tbody.innerHTML = '';
      upperList.forEach((name, i) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td class="rank">${i+1}</td>
          <td class="pokemon">${name}</td>
          <td class="check-col">
            <input type="checkbox" ${currentChecks[i]?'checked':''} onchange="currentChecks[${i}]=this.checked">
          </td>
        `;
        tbody.appendChild(tr);
      });
    }

    function saveCandidate() {
      const name = document.getElementById('candName').value.trim();
      if (!name) return alert("候補名を入力してください");
      saveToStorage(name);
    }

    function overwriteSelected() {
      const select = document.getElementById('candidateSelect');
      const name = select.value;
      if (!name) return alert("上書きしたい候補を選択してください");
      if (confirm(`「${name}」を上書きしますか？`)) {
        saveToStorage(name);
      }
    }

    function saveToStorage(name) {
      let saved = JSON.parse(localStorage.getItem('teamCandidates') || '{}');
      saved[name] = currentChecks.slice();
      localStorage.setItem('teamCandidates', JSON.stringify(saved));
      updateSelect();
      alert(`「${name}」を保存/更新しました`);
    }

    function deleteSelected() {
      const select = document.getElementById('candidateSelect');
      const name = select.value;
      if (!name) return alert("削除する候補を選択してください");
      if (!confirm(`「${name}」を削除しますか？`)) return;
      
      let saved = JSON.parse(localStorage.getItem('teamCandidates') || '{}');
      delete saved[name];
      localStorage.setItem('teamCandidates', JSON.stringify(saved));
      updateSelect();
      alert("削除しました");
    }

    function updateSelect() {
      const select = document.getElementById('candidateSelect');
      select.innerHTML = '';
      const saved = JSON.parse(localStorage.getItem('teamCandidates') || '{}');
      Object.keys(saved).forEach(name => {
        const opt = document.createElement('option');
        opt.value = name;
        opt.textContent = name;
        select.appendChild(opt);
      });
    }

    function showComparison() {
      const select = document.getElementById('candidateSelect');
      const selected = Array.from(select.selectedOptions).map(o => o.value);
      if (selected.length === 0) return alert("Ctrlを押しながら複数選択してください");

      const savedData = JSON.parse(localStorage.getItem('teamCandidates') || '{}');
      const header = document.getElementById('compareHeader');
      const body = document.getElementById('compareBody');

      header.innerHTML = '<th class="rank">順位</th><th class="pokemon">上位ポケモン</th>';
      selected.forEach(name => {
        const th = document.createElement('th');
        th.className = 'candidate-col';
        th.textContent = name;
        header.appendChild(th);
      });

      body.innerHTML = '';
      upperList.forEach((poke, i) => {
        const tr = document.createElement('tr');
        tr.innerHTML = `<td class="rank">${i+1}</td><td class="pokemon">${poke}</td>`;
        selected.forEach(name => {
          const checks = savedData[name] || [];
          const td = document.createElement('td');
          td.textContent = checks[i] ? '✓' : '';
          if (checks[i]) td.classList.add('good');
          tr.appendChild(td);
        });
        body.appendChild(tr);
      });

      document.getElementById('compareTable').style.display = 'table';
    }

    function clearCurrent() {
      if (confirm("現在のチェックをクリアしますか？")) {
        currentChecks.fill(false);
        renderCheckTable();
      }
    }

    function updateRanking() {
      const text = document.getElementById('rankingInput').value.trim();
      if (text) {
        localStorage.setItem('customRanking', text);
        loadRanking();
        renderCheckTable();
        alert("ランキングを更新しました");
      }
    }

    // 初期化
    loadRanking();
    document.getElementById('rankingInput').value = upperList.join('\n');
    renderCheckTable();
    updateSelect();
  </script>
</body>
</html>
