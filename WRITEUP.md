# Writeup
この問題のおかしなところにお気づきでしょうか．
そう，ブレザーは英語で blazor ではなく blazer なのです．
これはスペルミスではなく，意図したヒントだったのです．

Blazor は， Web アプリにおいてクライアント上での動作を .NET で実現できる技術です．
つまり C# がブラウザ上で動作するのです．
詳細については Microsoft の公式ページをご覧ください:
https://dotnet.microsoft.com/apps/aspnet/web-apps/blazor

さて，一般的なブラウザには，開いている Web ページがどのような通信を行っているか監視する機能が存在します．
例えば Google Chrome では，ページを右クリックして _Inspect_ または _要素を検証_ を選択すると，開発者ツールを開くことができます．
そのうち _Network_ タブで，先述したような監視を行えます．

この問題のページを監視した状態で読み込むと，多数の `.dll` ファイルを取得していることに気が付きます．
DLL (Dynamic Link Library) は主に Windows で使われる形式のはずです．
どうしてブラウザでその形式のファイルが扱えているのでしょうか？
それは，先述した Blazor による成果です． Blazor は， WebAssembly という技術を用いて .NET ランタイムを提供します．
WebAssembly はマルチプラットフォームに対応しており，ブラウザで動くので，これらの DLL ファイルを読み込むことができます．

つまり，この問題のページは C# で書かれており，そのビルド成果物はこの DLL ファイルのいずれかにある，ということが予測できます．
ファイル名を眺めると， `System.` や `Microsoft.` で始まるものがほとんどの中で， `SailorOrBlazor.dll` というファイルが特徴的です．
これが一番怪しいのではないかと踏むことができるでしょう．

DLL 形式といっても， .NET においては通常 MSIL という中間言語で構成されます．
機械語までコンパイルされているわけではないので，比較的高い精度で元のコードを復元することができます．
著名なデコンパイラには JetBrains dotPeek や ILSpy などが存在します．
また JetBrains Rider にもデコンパイラが同梱されています．
いずれかのツールでこのファイルを読み込めば，このページの動作を決定するコードが見つかるはずです．

以下は JetBrains Rider に付属のデコンパイラでの結果の抜粋です:

```cs
private void Judge()
{
  byte[] bytes1 = Encoding.ASCII.GetBytes(this._answer);
  byte[] bytes2 = new byte[bytes1.Length];
  for (int index1 = 0; index1 < bytes1.Length; ++index1)
  {
    int num1 = (int) bytes1[index1];
    byte[] numArray = bytes2;
    int index2 = index1;
    int num2 = num1;
    int num3;
    switch (index1 % 4)
    {
      case 0:
        num3 = 36;
        break;
      case 1:
        num3 = 18;
        break;
      default:
        num3 = 32;
        break;
    }
    numArray[index2] = (byte) (num2 ^ num3);
  }
  this._result = !(Encoding.ASCII.GetString(bytes2) == "(省略)`]") ? "Incorrect, try again." : "Correct!";
  this._answer = "";
}
```

これを整理すると，以下のような擬似コードになります:

```cs
byte[] answer = 入力された答え;
byte[] computed = [];

for (int i = 0; i < answer.Length; ++i)
{
    byte key = (i % 4) switch {
        0 => 0x24,  // 36
        1 => 0x12,  // 18
        _ => 0x20,  // 32
    }
    
    computed[i] = answer[i] ^ key;
}

result = computed == SECRET ? "Incorrect, try again." : "Correct!";
```

ただし `^` は XOR を表します．

すなわち答えと `241220202412...` を XOR したものがハードコーディングされた値と等しいことを検証しています．
逆の操作をすれば元の答えが分かることになるので，ハードコーディングされた値をもう一度 `241220202412...` と XOR すればフラグが手に入ります！
