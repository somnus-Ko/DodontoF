#--*-coding:utf-8-*--

class Elysion < DiceBot
  
  def initialize
    super
    @d66Type = 2
  end
  
  
  def prefixs
    ['date.*', 'EL.*', 
     'RBT', 'SBT', 'BBT','CBT','DBT','IBT','FBT','LBT','PBT','NBT','ABT','VBT','GBT',
     'BFT', 'FWT', 'FT',
     'SRT', 'ORT', 'DRT', 'URT'
     ]
  end
  
  def gameName
    'エリュシオン'
  end
  
  def gameType
    "Elysion"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定（ELn+m）
　能力値 n 、既存の達成値 m（アシストの場合）
例）EL3　：能力値３で判定。 
　　EL5+10：能力値５、達成値が１０の状態にアシストで判定。
・ファンブル表 FT
・戦場表 BFT
・致命傷表 FWT
・休憩表（〜BT）
  教室 RBT／購買 SBT／部室 BBT／生徒会室 CBT／学生寮 DBT／図書館 IBT／屋上 FBT／研究室 LBT／プール PBT／中庭 NBT／商店街 ABT／廃墟 VBT／ゲート GBT
 ・ランダムNPC表（〜RT）
　学生生活関連NPC表 SRT／その他NPC表 ORT／学生図鑑 下級生表 DRT／学生図鑑 上級生表 URT
・デート表（DATE）
　2人が「DATE」とコマンドをそれぞれ1回ずつ打つと、両者を組み合わせてデート表の結果が表示されます。
・デート表（DATE[PC名1,PC名2]）
　1コマンドでデート判定を行い、デート表の結果を表示します。
・D66ダイスあり
MESSAGETEXT
  end
  
#  教室 R:classRoom／購買 S:Shop／部室 B:Box／生徒会室 C:Council／学生寮 D:Dormitory／図書館 I:lIbrary／屋上 F:rooF／
#　研究室 L:Labo／プール P:Pool／中庭 N:iNner／商店街 A:Avenue／廃墟 V:deVastation／ゲート G:Gate
  
  def changeText(string)
    string
  end
  
  def dice_command(string, name)
    string = @@bcdice.getOriginalMessage
    debug('dice_command string', string)
    
    secret_flg = false
    
    prefixsRegText = prefixs.join('|')
    
    unless ( /(^|\s)(S)?(#{prefixsRegText})/i =~ string )
      debug("NOT match")
      return '1', secret_flg
    end
    
    debug("matched.")
    
    secretMarker = $2
    command = $3
    
    output_msg = executeCommand(command)
    
    debug('secretMarker', secretMarker)
    if( secretMarker )
      debug("隠しロール")
      secret_flg = true unless( output_msg.empty? )
    end
    
    unless( output_msg.empty? )
      output_msg = "#{name}: #{output_msg}"
      debug("rating output_msg, secret_flg", output_msg, secret_flg)
    else
      output_msg = '1'
    end
      
    return output_msg, secret_flg
  end
  
  
  def executeCommand(command)
    debug('executeCommand command', command)

    result = ''
    case command
    when /EL(\d*)(\+\d+)?/i
      base = $1
      modify = $2
      result= check(base, modify)
      
    when /DATE\[(.*),(.*)\]/i
      pc1 = $1
      pc2 = $2
      result = getDateBothResult(pc1, pc2)
      
    when /DATE(\d\d)(\[(.*),(.*)\])?/i
      number = $1.to_i
      pc1 = $3
      pc2 = $4
      result =  getDateResult(number, pc1, pc2)
      
    when /DATE/i
      result =  getDateValue
      
    else
      result = checkAnyCommand(command)
    end
    
    
    return '' if result.empty? 
    
    return "#{command} ＞ #{result}"
  end
  
  
  def checkAnyCommand(command)
    result = 
      case command.upcase
      when 'RBT'
        getClassRoomBreakTable
      when 'SBT'
        getSchoolStoreBrakeTable
      when 'BBT'
        getClubRoomBrakeTable
      when 'CBT'
        getStudentCouncilBrakeTable
      when 'DBT'
        getDormitoryBrakeTable
      when 'IBT'
        getLibraryBrakeTable
      when 'FBT'
        getRoofBrakeTable
      when 'LBT'
        getLaboratoryBrakeTable
      when 'PBT'
        getPoolBrakeTable
      when 'NBT'
        getInnerCourtBrakeTable
      when 'ABT'
        getShoppingAvenueBrakeTable
      when 'VBT'
        getDevastationBrakeTable
      when 'GBT'
        getGateBrakeTable
      when 'BFT'
        getBattleFieldTable
      when 'FWT'
        getFatalWoundsTable
      when 'FT'
        getFumbleTable
      when 'SRT'
        getRandomNpcSchoolLife
      when 'ORT'
        getRandomNpcOther
      when 'DRT'
        getRandomNpcDownClassmen
      when 'URT'
        getRandomNpcUpperClassmen
      else
        ''
    end
    
    return result
  end
  
  
  def check(base, modify)
    base = getValue(base)
    modify = getValue(modify)
    
    dice1, dummy = roll(1, 6)
    dice2, dummy = roll(1, 6)
    
    diceTotal = dice1 + dice2
    addTotal = base + modify
    total = diceTotal + addTotal
    
    result = ""
    result << "(2D6#{getValueString(base)}#{getValueString(modify)})"
    
    if dice1 == dice2
      result << " ＞ #{diceTotal}[#{dice1},#{dice2}] ＞ #{diceTotal}"
      result << getSpecialResult(dice1, total)
      return result
    end
    
    result << " ＞ #{diceTotal}[#{dice1},#{dice2}]#{getValueString(addTotal)} ＞ #{total}"
    result << getCheckResult(total)
    
    return result
  end
  
  def getValue(string)
    return 0 if string.nil? 
    return string.to_i
  end
  
  def getValueString(value)
    return "+#{value}" if value > 0
    return "-#{value}" if value < 0
    return ""
  end
  
  
  def getCheckResult(total)
    success = getSuccessRank(total)
    
    return " ＞ 失敗" if success == 0
    return getSuccessResult(success)
  end
  
  def getSuccessResult(success)
    
    result = " ＞ 成功度#{success}"
    result << " ＞ 大成功 《アウル》2点獲得" if success >= @@successMax
    
    return result
  end
  
  @@successMax = 5
  
  def getSuccessRank(total)
    success = ((total - 9) / 5.0).ceil
    success = 0 if success < 0 
    success = @@successMax if success > @@successMax
    return success
  end
  
  
  def getSpecialResult(number, total)
    debug("getSpecialResult", number)
    
    if number == 6
      return getCriticalResult
    end
    
    return getFambleResultText(number, total)
  end
  
  def getCriticalResult
    getSuccessResult(@@successMax)
  end
  
  def getFambleResultText(number, total)
    debug("getFambleResultText number", number)
    
    if number == 1
      return " ＞ 大失敗"
    end
    
    result = getCheckResult(total)
    result << " ／ (#{number -1}回目のアシストなら)大失敗"
    
    debug("getFambleResultText result", result)
    
    return result
  end
  
  def getDateBothResult(pc1, pc2)
    dice1, dummy = roll(1, 6)
    dice2, dummy = roll(1, 6)
    
    result =  "#{pc1}[#{dice1}],#{pc2}[#{dice2}] ＞ "
    
    number = dice1 * 10 + dice2
    
    if( dice1 > dice2 )
      tmp = pc1
      pc1 = pc2
      pc2 = tmp
      number = dice2 * 10 + dice1
    end
    
    result <<  getDateResult(number, pc1, pc2)
    
    return result
  end
  
  def getDateResult(number, pc1, pc2)
    
    name = 'デート'
    
    table = [
             [11, '「こんなはずじゃなかったのにッ！」仲良くするつもりが、ひどい喧嘩になってしまう。この表の使用者のお互いに対する《感情値》が1点上昇し、属性が《敵意》になる。'],
             [12, '「あなたってサイテー!!」大きな誤解が生まれる。受け身キャラの攻め気キャラ以外に対する《感情値》がすべて0になり、その値のぶんだけ攻め気キャラに対する《感情値》が上昇し、その属性が《敵意》になる。'],
             [13, '「ねぇねぇ知ってる…？」せっかく二人きりなのに、他人の話で盛り上がる。この表の使用者は、PCの中からこの表の使用者以外のキャラクター一人を選び、そのキャラクターに対する《感情値》が1点上昇する。'],
             [14, '「そこもっとくわしく！」互いの好きなものについて語り合う。受け身キャラは、攻め気キャラの「好きなもの」一つを選ぶ。受け身キャラは、自分の「好きなもの」一つをそれに変更したうえで、攻め気キャラへの《感情値》が2点上昇し、その属性が《好意》になる。'],
             [15, '「なぁ、オレのことどう思う？」思い切った質問！受け身キャラは、攻め気キャラに対する《感情値》を2上昇させ、その属性を好きなものに変更できる。'],
             [16, '「あなたのこと心配してるわけじゃないんだからね！」少し前の失敗について色々と言われてしまう。ありがたいんだけど、少しムカつく。受け身キャラは、攻め気キャラに対する《感情値》が2点上昇する。'],
             [22, '「え、もうこんな時間!?」一休みするつもりが、気がつくとかなり時間がたっている。この表の使用者のお互いに対する《感情値》が1点上昇し、《アウル》1点を獲得する。'],
             [23, '「気になってることがあるんだけど…？」何気ない質問だが、これは難しい。変な答えはできないぞ。攻め気キャラは〔学力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [24, '「なんか面白いとこ連れてって」うーん、これは難しい注文かも？攻め気キャラは、〔政治力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [25, '「うーん、ちょっと困ったことがあってさ」悩みを相談されてしまう。ここはちゃんと答えないと。攻め気キャラは、〔青春力〕で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [26, '「天魔だ。後ろにさがってろ！」何処からとも無く現れた天魔に襲われる。攻め気キャラは好きな能力値で判定を行う。成功すると、この表の使用者のお互いに対する《感情値》が成功度の値だけ上昇し、その属性が《好意》になる。失敗すると、互いに1D6点のダメージを受けつつ、何とか危機を切り抜けることができるが、受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《敵意》になる。'],
             [33, '「ごめん、勘違いしてた」誤解が解ける。この表の使用者のお互いに対する《感情値》が1点上昇し、《好意》になる。'],
             [34, '「これ、キミにしか言ってないんだ。二人だけの秘密」受け身キャラが隠している夢や秘密を攻め気キャラが知ってしまう。受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [35, '「これからも、よろしく頼むぜ。相棒」攻め気キャラが快活に微笑む。受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [36, '「わ、わたしは、あなたのことが…」受け身キャラの思わぬ告白！受け身キャラの攻め気キャラに対する《感情値》が2点上昇する。'],
             [44, '「大丈夫？痛くないか？」互いに傷を治療しあう。この表の使用者は、お互いの自分に対する[《好意》×1D6]点だけ、自分の《生命力》を回復する事ができる。でちらかの《生命力》が1点以上回復したら、この表の使用者のお互いに対する《感情値》が1点上昇する。'],
             [45, '「この事件が終わったら、伝えたい事が…あるんだ」攻め気キャラの真剣な言葉。え、それって…？受け身キャラの攻め気キャラに対する《感情値》が1点上昇し、その属性が《好意》になる。エピローグに攻め気キャラが生きていれば、この表の使用者のお互いに対する《感情値》がさらに2点上昇する。ただし、以降このセッションの間、攻め気キャラは「致命傷表」を使用したとき、二つのサイコロを振って低い目を使う。'],
             [46, '「停電ッ!?…って、どこ触ってるんですかッ!?」辺りが不意に暗くなり、思わず変なところを触ってしまう。攻め気キャラの受け身キャラに対する《感情値》が2点上昇し、その属性が《好意》になる。また、受け身キャラの攻め気キャラに対する《感情値》が2点上昇し、その属性が《敵意》になる。'],
             [55, '「お前ってそんなやつだったんだ？」意外な一面を発見する。互いに対する《感情値》が1点上昇し、その属性が反転する。'],
             [56, '「え？え？えぇぇぇぇッ?!」ふとした拍子に唇がふれあう。受け身キャラの攻め気キャラ以外に対する《感情値》が全て0になり、その値の分だけ攻め気キャラに対する《感情値》が上昇し、その属性が《好意》になる。'],
             [66, '「…………」気がつくとお互い、目をそらせなくなってしまう。そのまま顔を寄せ合い…。この表の使用者のお互いに対する《感情値》が3点上昇する。'],
            ]
    
    debug("number", number)
    text = get_table_by_number(number, table)
    text = changePcName(text, '受け身キャラ', pc1)
    text = changePcName(text, '攻め気キャラ', pc2)
    
    return "#{name}(#{number}) ＞ #{text}"
  end
    
  def changePcName(text, base, name)
    return text if name.nil? or name.empty?
    
    return text.gsub(/(#{base})/){$1 + "(#{name})"}
  end
  
  
  def getDateValue
    dice1, dummy = roll(1, 6)
    return "#{dice1}"
  end
  
  
  def getClassRoomBreakTable
    name = '教室'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が真夜中パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。真夜中パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "引き出しのパン\n「お！こんなとこにッ!?」机の中に以前買った食べ物を発見する。アイテムの【焼きそばパン】を一つ獲得する。使用するときに1D6を振ること。奇数が出たら、問題なく使用できる。偶数が出たら、それは腐っている。【焼きそばパン】の効果の変わりに「病気」の変調を受ける事。",
             "授業の質問\n「ねぇねぇ、ここ分かる？」クラスメイトに授業の質問を受ける。〔学力〕で判定を行う。成功すると、質問に答えるうちに自分の理解も深まる。自分の授業欄の中から好きなもの一つを選び、□にチェックを入れる。",
             "先生の依頼\n「丁度いいところにいるな。手伝ってくれ」先生に用事を言いつけられる。〔政治力〕で判定を行う。成功すると、感謝されてアイテムの【タリスマン】を一つ獲得する",
             "誰かの視線\n……誰かの視線を感じる。もしかして？　教室にいるキャラクターの中から好きな者を一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する。（教室に誰がいるのかは、最終的にGMが決定すること）。",
             "遊びの誘い\n「ねぇねぇ、明日の放課後ひま？」クラスメイトに遊びに誘われる。翌日の放課後、自由行動として「遊び」を行うことができる。「遊び」を行うと、《アウル》が1D6点回復する。",
             "居眠り\n「ZZZ……」教室での居眠りは最高だ。《アウル》1点を変調一つを回復する。ただし、今が授業パートなら、〔青春力〕で判定を行う。失敗すると、先生に怒られて《生命力》が1D6点減少し、《アウル》も変調も回復しない。",
             "お腹空いた\n「ねぇねぇ。お腹空いた。なんかない？」クラスメイトに食事をねだられた。分類が「食物」のアイテムを一つ消費することができたら、教室にいるキャラクターの中から好きな者を一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する。",
             "クラスの噂\n「ねぇねぇ、これ知ってる？」クラスメイトの噂話……。〔政治力〕の判定を行う。成功すると、手がかり一つを選び、その情報を公開する。失敗すると、あなたについての噂をたてられる。あなたの周囲に、あなたに対して《感情値》を持つキャラクターがいたら、それを反転させる。",
             "ラブレター!?\n「こ、これは……ッ!?」机の中に何かを発見。〔青春力〕で判定を行う。成功すると、誰かからのラブレターを発見！ 好きなNPC一人を選び、そのキャラクターの自分に対する《感情値》が1点上昇し、属性を《好意》にする。",
             "笑い声\n「あはははははは」にぎやかな笑い声が響く。〔青春力〕で判定を行う。成功したら輪の中に溶け込み、《アウル》が1点回復する。失敗すると「孤独」の変調を受ける。",
            ]
    getBreakTable(name, table)
  end
  
  def getSchoolStoreBrakeTable
    name = '購買'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "まとめ買いセール\n「まとめ買いセール！」好きなアイテムを一つ選ぶ。そのアイテムの調達の判定を一度行う事ができる。このとき、そのアイテムの価格を1高くするたび、追加でもう一個そのアイテムを獲得することができる。",
             "防具セール！\n「うわぁ。これ欲しいなぁ」セール品を見つける。分類が「防具」のアイテムの中から好きなものを一つ選ぶ。そのアイテムの価格が1低いものとして調達の判定を一度行うことができる（ただし1未満にはならない）。",
             "武器セール！\n「何と！こんなものまで！」セール品を見つける。分類が「武器」のアイテムの中から好きなものを一つ選ぶ。そのアイテムの価格が1低いものとして調達の判定を一度行うことができる（ただし1未満にはならない）。",
             "色々セール！\n「ほほう！これはお買い得！」セール品を見つける。分類が「一般」のアイテムの中から好きなものを一つ選ぶ。そのアイテムの価格が1低いものとして調達の判定を一度行うことができる（ただし1未満にはならない）。",
             "ウィンドウショッピング\n「へぇ、こんな商品出たんだ」ウインドウショッピングでも、結構気分は晴れるもんだよね。《アウル》が1点回復する。",
             "試食\n「お！良かったら食べてみて！」新商品の試食を頼まれる。1D6を振ること。奇数なら美味しさのあまり《生命力》が1D6点と「空腹」の変調が回復する。偶数なら微妙すぎて《生命力》が1点減少する。",
             "購買での出会い\n「……あ」陳列棚の商品に伸ばした手と手が触れあう。購買にいるキャラクターの中から好きなキャラクターの自分に対する《感情値》が1点上昇する（購買に誰がいるのかは、最終的にGMが決定すること）。",
             "高価買い取り！\n「いいもの持ってるね。よかったら、それ引き取るよ」好きなアイテム一つと【お金】一つを交換することができる。",
             "デリバリー\n「あー、今は品切れだねぇ。補充したら届けるよ」好きなアイテムを一つ選ぶ。そのアイテムの調達の判定を一度行うことができる。調達の判定に成功すると、そのアイテムを次のパート以降、好きなタイミングで入手することができる。",
             "サイフ紛失\n「あれ？ あれれれッ!?」サイフを落としてしまった。【お金】を持っていたら、それを全て失う。",
            ]
    getBreakTable(name, table)
  end
  
  def getClubRoomBrakeTable
    name = '部室'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "謎の忠告\n「霊があなたに何かを訴えかけようとしてる…」〔政治力〕の判定を行う。成功すると、手がかり一つを選び、その情報を公開する。失敗すると「恐怖｣の変調を受ける。",
             "後輩現る！\n「どこまでもついていきますよ先輩!」いつのまにか可愛い後輩ができていた。もしも【クラブ】のコミュを修得していたら、アイテムの【後輩】一つを獲得する。",
             "先輩現る！\n「おう、さしいれ持ってきたぞ!」先輩がやってくる。アイテムの「ごちそう」を一つ獲得する。",
             "青春の汗\n「ダハハハ！ 青春の汗を流そうぜ！」部室の中から体育会系部員の熱い会話が聞こえてきた。好きな能力値で判定を行う。成功すると、このセッションの間、〔青春力〕の修整が1点上昇する。失敗すると「バカ」の変調を受ける。",
             "茶飲み話\n「まぁまぁ。お茶でも飲んでいきなよ」知り合いの所属する部室でお茶を飲む。〔政治力〕の判定を行う。成功すると、《アウル》が1点回復する。",
             "熱い議論「もっと本質的な部分に目を向けようよ！」部室の中から文科系部員の高度な会話が聞こえてきた。好きな能力値で判定を行う。成功すると、このセッションの間、〔学力〕の修整が1点上昇する。失敗すると「孤独」の変調を受ける。",
             "マネージャー\n「あれ？ ケガしてるじゃないですか」もしも【クラブ】のコミュを修得していたら、可愛いマネージャーが絆創膏をくれる。《生命力》が1D6点回復する。",
             "突然の料理\n「ちょっと付き合えよ」もしも【クラブ】のコミュを修得していたら、仲間の部員に呼び止められる。〔政治力〕で判定を行う。成功すると、自分の放課後欄の中から好きな【クラブ】一つを選び、□にチェックを入れる。",
             "仲間の告白\n「キミ、最近なんかいい感じだよね」もしも【クラブ】のコミュを修得していたら、部室にいるキャラクターの中から好きな者を一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する（部室に誰がいるのかは、最終的にGMが決定する事）",
             "門外不出品？\n「なんだこれ……？」部室の奥から、いわれのありそうな古書が出てくる。外国の言葉で書かれているみたいだけど……？〔学力〕で判定を行う。必要な成功度は、自分のカオスレートの絶対値となる（1未満にはならない）。成功すると、そのセッションの間、自分のカオスレートを1点上昇するか、1点減少する。",
            ]
    getBreakTable(name, table)
  end

  def getStudentCouncilBrakeTable
    name = '生徒会室'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が真夜中パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。真夜中パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "秘密の会話\n「これ……極秘……はい……早急……対処……」生徒会質の面々の内緒話が漏れ聞こえてくる。これはいいことを聞かせてもらった。次に自分が調査の判定を行ったとき、その達成値が3点上昇する。",
             "天魔情報\n「むむ！これは……」天魔に対する情報を検索していたら、気になる情報が……。〔学力〕の判定を行う。成功すると、このシナリオに登場する可能性のある天魔の種類すべてをGMから教えてもらえる。",
             "気になるあいつ\n「不運。そういう名前なのか、あいつ」もしこのシナリオに登場しているＮＰＣで、名前がわからないキャラクターがいたら、それを知ることができる。また、「好きなもの」と「嫌いなもの」が分からないキャラクターがいたら、「単語表」を使ってランダムに決める事ができる。",
             "調べられてる？\n「あれ、これって……？」誰かが自分のことを検索した形跡がある。〔政治力〕で判定を行う。成功すると、自分について調査していた人物を発見！好きなＮＰＣ一人を選び、そのキャラクターの自分に対する《感情値》が1点上昇する。",
             "プロフィール更新\n「自分のプロフィールを更新しておこう」〔政治力〕で判定を行う。成功すると、好きなキャラクター一人を選ぶ。そのキャラクターの自分に対する《感情値》の属性を《好意》にすることができる。",
             "思わぬ一面\n「へぇ。こいつって、こんなヤツだったんだ」生徒会質で知り合いの思わぬ一面を知る。自分が《感情値》を持っているキャラクター一人を選ぶ。そのキャラクターへの《感情値》の属性を反転する。",
             "友達検索\n「折角なんで、あいつのこと調べてみるか」友人の情報を検索してみる。〔政治力〕で判定を行う。成功すると、ＰＣの中から好きなキャラクター一人を選ぶ。そのキャラクターに対する《感情値》が1点上昇する。",
             "同僚との遭遇\n「こんなとこで何してんの？」もしも【委員会】のコミュを修得していたら、仲間の委員に呼び止められる。〔政治力〕で判定を行う。成功すると、自分の放課後欄の中から好きな【委員会】一つを選び、□にチェックを入れる。",
             "旧友との再会\n「おう！久しぶりッ!!」昔の友人とばったり再会。〔青春力〕の判定を行う。成功すると、昔貸していた本を返してくれる。アイテムの【参考書】を一つ獲得する。",
             "謎の警告\n「深追いはするな。これは警告だ」携帯電話に謎の脅迫メールが届く。何者かに目をつけられたようだ。〔政治力〕で判定を行う。失敗すると「恐怖」の変調を受ける。",
            ]
    getBreakTable(name, table)
  end

  def getDormitoryBrakeTable
    name = '学生寮'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "友達との時間\n「だよねー」友達の部屋でお茶とお菓子をごちそうになる。《生命力》が1D6点、《アウル》が1点回復する。",
             "思い出の日\n寮の友人とハメを外して、寮長に怒られる。学生寮にいるキャラクターの中から好きな者を一人選ぶ。自分とそのキャラクターは「バカ」の変調を受け、お互いに対する《感情値》が2点上昇する（寮に誰がいるのかは、最終的にGMが決定する事）。",
             "引越しの手伝い\n「あ、今日からここに住む者です。よろしく」行きがかり上、引越しの手伝いをすることに。〔青春力〕で判定を行う。成功すると、感謝されてアイテムの【ごちそう】を一つ獲得する。",
             "色々トーク\n友達を自分の部屋に呼んでボーイズトーク！ガールズトーク♪　「青春力」の判定を行う。成功すると、自分に対して《好意》を持っている同姓のキャラクター全員の、自分に対する《感情値》が1点上昇する。判定に失敗するか、自分に対して《好意》を持っているキャラクターが一人もいないと「孤独」の変調を受ける。",
             "好物発見！\n「お、ラッキー♪」冷蔵庫の中に好物を発見。分類が「食物」のアイテムの中から好きなものを一つ選ぶ。それを一つ獲得する。使用するときに1D6を振ること。奇数が出たら、問題なく使用できる。偶数が出たら、それは腐っている。そのアイテムの効果の代わりに「病気」の変調を受ける事。",
             "お見舞い\n「ねぇ、大丈夫？」もしも「病気」か「孤独」の変調を受けていたら、友人がお見舞いに来てくれる。好きなキャラクター一人を選ぶ。自分とそのキャラクターは、お互いに対する《感情値》が1点上昇する。そして好きな変調一つが回復する。",
             "魔蟲襲来！\n「カサカサカサ……」黒くて素早く動くアイツが現れた！〔学力〕で判定を行う。失敗すると、《アウル》が1点減少する。",
             "恋の相談\n寮の友人から恋人に関する相談を受ける。もしも【恋人】のコミュを修得していたら、《アウル》が2点回復する。修得していなかったら「孤独」の変調を受ける。",
             "寮に潜入\n「こっそり遊びにきてみない？」異性の友人を呼んでスリルを味わう。好きなキャラクター一人を選び、「青春力」で判定を行う。成功すると、自分とそのキャラクターは《アウル》が2点回復する。失敗すると、互いに対する《感情値》が1点減少する。",
             "ささいなケンカ\n「なんだとーッ！」「なにをーッ！」ささいな行き違いから、他の住人とケンカになってしまう。〔青春力〕か〔政治力〕で判定を行う。〔青春力〕の判定に失敗すると《生命力》が2D6点減少する。〔政治力〕の判定に失敗すると「孤独」の変調を受ける。",
            ]
    getBreakTable(name, table)
  end

  def getLibraryBrakeTable
    name = '図書館'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "重たい空気\n静かな気配に圧倒される。とりあえず手近にあった本のページを開いてみるが……。〔学力〕で判定を行う。失敗すると「バカ」の変調を受ける。",
             "文献調査\n「過去にも似たような事件があったようだ」文献を調べる。次に自分が調査の判定を行ったとき、その達成値が3点上昇する。",
             "天魔対策\n「アイツの習性は……」天魔の事を調べる。天使か悪魔のエネミー一種を選んで、〔学力〕の判定を行う。成功すると、そのセッションの間、そのエネミーの攻撃に対して、ガード判定を行う場合、その達成値が2点上昇する。",
             "物語の世界へ\n「…………」シーンと静まり返った雰囲気の中、読書が進む。本の中にどんどん入り込んでいく。すべての変調が回復し、「空腹」の変調を受ける。",
             "本の貸し出し\n「へー、こんな本もあるんだ」アイテムの【週刊誌】か【参考書】のいずれか一つを獲得する。",
             "授業の予習\nせっかく図書館に来たので、気になっていた科目について調べる。〔学力〕で判定を行う。成功すると、疑問点が解消される。自分の授業欄の中から好きなものを一つ選び、□にチェックを入れる。",
             "図書館での出会い\n「……あ」書架の本に伸ばした手と手が触れ合う。図書館にいるキャラクターの中から好きな者を一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する（図書館に誰がいるのかは、最終的にGMが決定する事）。",
             "書物の夢\n本を読んでいるうちにいつの間にか眠ってしまったようだ。何か面白い夢を見たような気がするんだけど……うーん、まだ眠い。「眠気」の変調を受け、《アウル》が2点回復する。",
             "謎の手紙\n「……ッ!?」本を開いてみると、そこにはあなた宛の手紙が……どうして、この本を読む事が分かったんだろう。〔青春力〕で判定を行う。成功すると、手がかり一つを選び、その情報を公開する。失敗すると、「恐怖」の変調を受ける。",
             "残念！\n目当ての本はすでに借りられていた。残念！《アウル》が1点減少する。",
            ]
    getBreakTable(name, table)
  end

  def getRoofBrakeTable
    name = '屋上'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "通り雨\n「キャ〜〜〜〜！」突然雨がふってきた！みんな屋上を去っていく。屋上にいるキャラクターの中から好きな者を一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する（屋上に誰がいるのかは、最終的にＧＭが決定すること）。",
             "自動販売機\n「なんで屋上に自動販売機があるんだ？」細かい事は気にせず何かのもう。〔政治力〕の判定を行う。成功すると、アイテムの【ポーション】か【お酒】か【タバコ】のいずれか一つを獲得できる。",
             "青空\n空を見上げると、自分がちっぽけな存在に思えてくる。〔青春力〕で判定を行う。成功すると、使用回数に制限がある授業かコミュを一つ選ぶ。その使用回数が一度分回復する。",
             "物思い\n空をながめながら、物思いにふける。俺ってアイツの事、どう思ってるんだろう？〔青春力〕で判定を行う。成功すると、ＰＣの中から好きなキャラクター一人を選ぶ。そのキャラクターに対する、《感情値》が1点上昇する。",
             "開放感\n開放的で非常に気分がいい。《アウル》が1点と「眠気」の変調が回復する。",
             "学園は広大だわ\n街並みを見下ろす。一体、この学園で何が起きているんだろう？〔学力〕で判定を行う。成功すると手がかり一つを選び、その情報を公開する。失敗すると、ほかの学生たちの姿が目に映り、今の自分に疑問がわいてくる。《アウル》が1点減少する。",
             "嵐の予感\n雲の動きが早くなっている。吹き荒ぶ風に、嵐の予感を感じた。〔青春力〕で判定を行う。成功すると、そのセッションの間、《アウル》の限界値が1点上昇する。失敗すると風に吹かれて風邪をひいてしまう。「病気」の変調を受ける。",
             "昼寝屋\nハンモックを貸し出している「昼寝屋」を発見。気持ちよさそうだ。〔政治力〕で判定を行う。成功すると、《生命力》が2D6点と「眠気」の変調が回復する。",
             "欲望の宴\n美味しそうな弁当を食べる者、恋人同士でイチャイチャするもの、怠惰な眠りを貪る者……屋上は欲望の見本市のようだ。「空腹」、「孤独」、「眠気」の内、好きな変調を受けることができる。受けた変調一種につき《アウル》が2点回復する。",
             "サビシガリヤ\n「……あなたも一人？」もしも「孤独」の変調を受けていたら、寂しそうな異性に声をかけられる。好きな異性のキャラクター一人を選ぶ。自分とそのキャラクターは、お互いに対する《感情値》が2点上昇する。そして好きな変調一つが回復する。",
            ]
    getBreakTable(name, table)
  end

  def getLaboratoryBrakeTable
    name = '研究室'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が真夜中パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。真夜中パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "装甲強化実験\n「ほう。面白い防具を使っているようだな」白衣を着た怪しげな生徒が防具の改造を申し出る。申し出を受け入れるなら、自分のもっている好きな防具一つを選んで、1D6を振る。奇数が出ると、そのセッションの間、その防具の装甲が1上昇する。偶数が出ると、その防具は破壊される。",
             "試薬\n「この試薬を飲んでみてくれないか」毒々しい色のポーションを渡される。「政治力」で判定を行う。失敗すると、断りきれずそれを飲むハメになる。。1D6を振る。奇数が出ると《生命力》が2D6点、《アウル》が1点回復する。偶数が出ると、「恐怖」と「病気」の変調を受ける。",
             "爆発事故\n「逃げろー！」研究室から数人の生徒が逃げ出してくる。なにかヤな予感。〔青春力〕で判定を行う。失敗すると、実験の爆発に巻き込まれる。《生命力》に2D6点のダメージを受ける。",
             "威力強化実験\n「ほう。面白い武器を使っているようだな」白衣を着た怪しげな生徒が武器の改造を申し出る。申し出を受け入れるなら、自分のもっている好きな武器一つを選んで、1D6を振る。奇数が出ると、そのセッションの間、その武器の威力が1上昇する。偶数が出ると、その武器は破壊される。",
             "命中強化実験\n「ほう。面白い武器を使っているようだな」白衣を着た怪しげな生徒が武器の改造を申し出る。申し出を受け入れるなら、自分のもっている好きな武器一つを選んで、1D6を振る。奇数が出ると、そのセッションの間、その武器に「精度２」の特殊効果が加わる（すでに「精度」の特殊効果のある武器は、その値が２上昇する）。偶数が出ると、その武器は破壊される。",
             "威力安定実験\n「ほう。面白い武器を使っているようだな」白衣を着た怪しげな生徒が武器の改造を申し出る。申し出を受け入れるなら、自分のもっている好きな武器一つを選んで、1D6を振る。奇数が出ると、そのセッションの間、その武器に「安定性３」の特殊効果が加わる（すでに「安定性」の特殊効果のある武器は、その値が１上昇する）。偶数が出ると、その武器は破壊される。",
             "バイオハザード\n「ピーーーー！ピーーーー！ピーーーー！」不吉な警告音が鳴り響く。バ、バイオハザードッ!?〔政治力〕で判定を行う。失敗すると、実験施設から漏れ出した奇妙な細菌に感染する。1D6を二回振って、ランダムに変調を二つ選び、それを受ける。",
             "ビーカーコーヒー\n「一杯やるかい？」ビーカーに注がれた珈琲を貰う。結構美味いんだけど、ちゃんと洗ってるのかな？「眠気」と「空腹」の変調が回復する。",
             "装甲安定実験\n「ほう。面白い防具を使っているようだな」白衣を着た怪しげな生徒が防具の改造を申し出る。申し出を受け入れるなら、自分のもっている好きな防具一つを選んで、1D6を振る。奇数が出ると、そのセッションの間、その防具に「堅牢２」の特殊効果が加わる（すでに「堅牢」の特殊効果のある防具は、その値が２上昇する）。偶数が出ると、その防具は破壊される。",
             "失敗作\n「そいつは失敗作だよ。欲しければ持っていって構わない」価格が３以下の好きなアイテム一つを選ぶ。それを一個獲得する。このアイテムは、持ち主がファンブルすると、破壊される。",
            ]
    getBreakTable(name, table)
  end

  def getPoolBrakeTable
    name = 'プール'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "熱いシャワー\n「……ふぅ」プールから出て、暖かいシャワーで冷えた体を暖める。疲れが少しずつほぐれていく。《生命力》が1D6点回復する。",
             "新作水着\n新しい水着の評判はどうかな？〔青春力〕の判定を行う。成功すると、プールにいるキャラクターの中から好きな者をその成功度と同じ人数だけ選び、そのキャラクターの自分に対する《感情値》が1点上昇する（プールに誰がいるのかは、最終的にＧＭが決定すること）。",
             "ポロリもあるよ\nプールからあがろうとしたき、思わず水着がポロリ。げげ。今の誰か見てたッ!?周囲にいる異性のキャラクターの自分に対する《感情値》の属性が反転する。",
             "熱視線\n誰かが、美しいフォームで飛び込み、水しぶきがあがる。思わず見惚れてしまう。プールにいるキャラクターの中から好きな者を一人選び、自分のそのキャラクターに対する《感情値》が1点上昇する（プールに誰がいるのかは、最終的にＧＭが決定すること）。",
             "眼福眼福\n水着がまぶしい!いい眺めかも……。《アウル》が1点回復する。",
             "人魚のように\n華麗なターンが決まり、周囲から賞賛の声があがる。プールにいるキャラクターの中から好きな者を一人を選び、そのキャラクターの自分に対する《感情値》が1点上昇する（プールに誰がいるのかは、最終的にＧＭが決定すること）。",
             "プカプカ\n水に浮かんでのんびりプカプカ。《アウル》が1点回復する。",
             "心地よい疲れ\n結構長い時間泳いだぞ。いい運動になったけど、お腹ペコペコダー。「空腹」の変調を受け、そのセッションの間、《生命力》の限界値が1D6点上昇する。",
             "記録に挑戦！\n「今日は、どこまで泳げるかな？」」自己新記録に挑戦！〔学力〕で判定を行う。成功すると、自己新記録を更新して《アウル》が2点回復する。失敗すると、溺れてしまう。《生命力》を2D6点減少する。",
             "地獄の特訓\n様々な地獄プールで特訓！みっちり自分の体をおいじめて、鍛えたぞ。〔青春力〕の判定を行う。成功すると、《生命力》が2D6点減少し、そのセッションの間、《生命力》の限界値が減少した《生命力》と同じ値だけ上昇する。",
            ]
    getBreakTable(name, table)
  end

  def getInnerCourtBrakeTable
    name = '中庭'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "オープンカフェ\nカフェテリアでお茶にする。優雅なひと時。《アウル》が1点回復する。",
             "犬登場\n「ワンワンワン！」不思議な犬がグラウンドに現れる。ここを掘れと言っているようだが……。1D6を振ること。奇数なら、地面にはお金が埋まっていた【お金】を一つ獲得する。偶数なら、低級の天魔が封印されていた。「学力」で判定を行う。失敗すると《生命力》に3D6点のダメージを受ける。",
             "観戦中\nグラウンドで行われている撃退士同士の特訓風景を眺めている。踏む。なるほどなぁ……。〔学力〕で判定を行う。成功すると、自分の授業欄の中から好きなものを一つ選び、□にチェックを入れる。",
             "占い師\n「そこのあなた。死相がでています。」そう言って、占い研のメンバーに呼び止められる。〔政治力〕の判定を行う。成功すると、危険を回避する方法を占ってもらうことができる。次に自分が判定で大失敗したとき、その判定のサイコロを1度だけ振り直すことができる。",
             "屋台\nお弁当屋さんや屋台が軒を並べている。美味しそうな匂いが漂ってきた。〔政治力〕の判定を行う。成功すると、色々な食事を食べて、《生命力》が1D6点と「空腹」の変調が回復する。",
             "特訓参加\n「おい、そこのお前！お前も一緒にやれ！」授業中の先生に、無理やり授業に参加させられる。ひたすら攻撃を避けまくる。ふは。疲れたー。《生命力》が2D6点減少し、そのセッションの間、《生命力》の限界値が減少した《生命力》と同じ値だけ上昇する。",
             "落し物\nあれ？こんなものが落ちてる。どうしたんだろう？ １なら【タバコ】、２なら【情報誌】、３なら【お洒落グッズ】、４なら【参考書】、５なら【阻霊符】、６なら【タリスマン】を一個獲得する。",
             "突然の告白！\n「先輩、ずっと前から憧れてました！」そう言って、後輩が告白して来た。え？ええッ!?突然の事に頭が真っ白になってしまった。好きな異性のキャラクター一人を選ぶ。そのキャラクターの自分に対する《感情値》が2点上昇する。その後、〔青春力〕で判定を行う。失敗すると「バカ」の変調を受ける。",
             "鉄球飛来！\n「おーい！危ないぞーッ!!」陸上部の投げた砲丸が飛んでくる。〔青春力〕で判定を行う。失敗すると《生命力》に2D6点のダメージを受ける。",
             "ちょっぴり贅沢\n今日は自分にご褒美。学食で贅沢しちゃおっかなー〔政治力〕で判定を行う。成功すると《生命力》が2D6点と《アウル》1点が回復する。",
            ]
    getBreakTable(name, table)
  end

  def getShoppingAvenueBrakeTable
    name = '商店街'
    table = [
             "風紀委員の巡回！\n「そこ、何やってる！」風紀委員に見つかった。現在が授業パートであれば、こっぴどく叱られる。〔政治力〕で判定を行う。失敗すると、次のパートは行動できない。授業パート以外であれば、心身ともにリフレッシュ。《アウル》が1点回復する。",
             "自習\nファーストフード店でレポート執筆。……あまり進まないなぁ。〔学力〕で判定を行う。成功度を2以上獲得すると、レポートは完成。自分の授業欄の中から好きなもの一つを選び、□にチェックを入れる。",
             "立ち話\n「よう。寄ってかないかい！」店の主人が陽気に声をかけてくる。〔政治力〕で判定を行う。成功すると、気になる話を聞かせてくれる。手がかり一つを選び、その情報を公開する。失敗すると、退屈な話に付き合わされる。「眠気」の変調を受ける。",
             "雰囲気のいい店\n「へぇ。こんな店あったんだ」とても雰囲気のいい店を見つける。次に自分がデート判定を行うとき、その達成値が2点上昇する。",
             "お気に入り！\n「おお！すごくいいッ!!」とってもこのみなオシャレアイテムを見つける。〔政治力〕の判定を行う。成功すると、アイテムの〔お洒落グッズ〕一個を獲得し、《アウル》1点を獲得する。",
             "大売出し\n「スーパークリアランスバザール！」お買い得なキャンペーンをやっている。アイテムの中から好きなものを一つ選ぶ。そのアイテムの価格が1低いものとして調達の判定を一度行う事ができる（ただし1未満にはならない）",
             "なじみの店\n先輩のアルバイトしているお店に遊びに行ってみた。色々サービスしてくれて大満足。《生命力》1D6点と《アウル》1点を回復する。",
             "休日\nお目当ての店に行ってみたら、シャッターが閉まっていた。どうやら臨時休業の模様。がっくりきて、《アウル》を1点減少する。",
             "泥棒\n「泥棒よー！捕まえてー！」商店街を走って逃げる不良生徒たち……捕まえるなら〔青春力〕で判定を行う。成功すると、泥棒を捕まえ、そのお礼としてアイテムの〔ポーション〕か〔タリスマン〕を一つ獲得する。失敗すると、泥棒を逃がした上に商店街の色々な場所を壊してしまい、しばらく出入り禁止に。このセッションの間、商店街で休憩を行うことができなくなる。",
             "福引\n福引をやっていた！1D6を振る。1〜5の目がでたら残念賞。アイテムの【焼きそばパン】一つを手に入れる。6の目がでたら【お金】を二つ手に入れる。",
             "家庭教師\n「ねぇねぇ、教えて酔う」近所の子供に勉強を教えてくれと頼まれる。〔学力で〕判定を行う。成功すると、彼らは尊敬の目できみを見つめる。アイテムの【後輩】を一つ獲得する。失敗すると「バカ」の変調を受ける。",
            ]
    getBreakTable(name, table)
  end

  def getDevastationBrakeTable
    name = '廃墟'
    table = [
             "迷子\n「きゃーーー！」少女がディアボロに襲われている。〔青春力〕で判定を行う。成功すると、少女を助けて感謝される。少女の自分に対する《感情値》が3点上昇し、その属性が《好意》になる。失敗すると、少女は命は取り留めたものの、傷つき倒れてしまう。《生命力》に2D6点のダメージと「孤独」変調を受ける。",
             "ライバル登場？\n「一度、お前と手合わせしてみたかったんだよ」撃退士らしき見覚えある人物が現れる。好きなＮＰＣを一人選び、そのキャラクターの自分に対する《感情値》が1点上昇する。",
             "無人の部屋\n「…………」誰もいないはずなのに、何かの気配がする。イヤな感じだ。〔青春力〕で判定を行う。成功すると、視線の正体を発見する。それはかわいい子猫だった。あまりのかわいらしさに《アウル》を1点獲得する。失敗すると「恐怖」の変調を受ける。",
             "戦いの跡\n戦いがあったであろう場所に、一振りの剣が突き刺さっていた。この剣の持ち主はどうなったんだろう…？アイテムの【大剣】一個を獲得する。",
             "裏の事情通\n「あんたの知りたい情報を売ってやろうか？」情報屋らしき男が情報の購入を持ちかける。手がかり一つを選び、調達の判定を一度行うことができる。情報の価格は、手がかりの[必要成功度-1（1未満にはならない)]になる。情報の調達に成功すると、その情報を公開する。",
             "怪しげな男\n「いいものがあるぜ。欲しいかい？]怪しげな男が【ポーション】を打っている。アイテムの【ポーション】の調達の判定を一度行うことができる。この【ポーション】の価格は3になるが、回復する《生命力》は3D6点になる。",
             "縄張り\n「おいおい、ここは俺たちの縄張りだぜ]不良たちに絡まれる。〔政治力〕で判定を行う。成功すると、不良たちは捨て台詞と共に逃げ出す。もし、廃墟に自分に対して《敵意》の属性の《感情値》の持ち主がいた場合、その属性を反転する（廃墟に誰がいるのかは、最終的にＧＭが決定すること）。失敗すると、1D6点のダメージを受ける。",
             "野良犬\n「グルルルルルッ！」野良犬たちが牙をむいている。〔青春力〕の判定を行う。失敗すると2D6点のダメージを受ける。",
             "隠れ家\n「学園だとどうしても気分が出なくてなぁ」【酒】か【タバコ】を何個でも使用することができる。ここで【酒】か【タバコ】を一個使用するたびに追加で《アウル》が1点回復する。また、ここで【酒】や【タバコ】を使った場合、その効果によって「眠気」や「孤独」の変調を受けない。",
             "実験\n「一度試してみたかったんだよな］ここでなら思い切り暴れても特に問題なさそうだ。あの技を試してみるか……。［青春力］で判定を行う。成功すると、自分の授業欄の中から好きなもの一つを選び、□にチェックを入れる。",
             "不良撃退士\n「ほう。いいもの持ってるじゃないか。そいつを寄こしたら見逃してやるよ」自分の携行品の中で一番価格の高いものを一つ選ぶ。それを渡せば特に何も起こらない。もし渡すのを断るのなら、〔青春力〕で判定を行う。成功度が2以下だった場合、3D6点のダメージを受ける。",
            ]
    getBreakTable(name, table)
  end

  def getGateBrakeTable
    name = 'ゲート'
    table = [
             "尋問\nゲート内にひそんでいた天魔から情報を収集する。〔政治力〕の判定を行う。成功すると、このシナリオに登場する可能性のある天魔の種類すべてをＧＭから教えてもらえる。失敗すると、1D6点のダメージを受ける。",
             "計略\n敵の計略に掛かる。〔政治力〕で判定を行う。失敗すると、ＧＭは手がかり一つを選ぶ。その手がかりの必要成功度が1上昇する。この効果は累積しない。",
             "活性化\n戦いを通じて、《アウル》の使い方を学んで行く。〔学力〕で判定を行う。成功すると、《アウル》を2点回復する。失敗すると、1D6点のダメージを受ける。",
             "克服\n無数の敵と戦ううちに、心が研ぎ澄まされていく。好きな能力地で判定を行う。成功すると、その成功度と同じ数だけ変調を回復する。失敗すると、1D6点のダメージを受ける。",
             "経験\nゲート内で多くの天魔と戦う。好きな能力値で判定を行う。成功すると、その成功度の数と同じだけ、成長欄のまだチェックの入っていない□をチェックする事ができる。失敗すると、1D6点のダメージを受ける。",
             "不意打ち\n「……あれは、もしや？］ゲートの中で、恐ろしい程の殺気の持ち主を見かける。もしや、今回の事件の黒幕か？彼に不意打ちを仕掛けることができる。不意打ちを仕掛けるなら〔青春力〕の判定を行う。成功すると、そのシナリオの黒幕（ボス）に［判定成功度×1］D6点のダメージを与える事ができる。失敗すると、3D6点のダメージを受ける。",
             "捜索\nゲート内を捜索する。〔学力〕で判定を行う。成功すると、「初期アイテム決定表」を一度使用し、そのアイテム一個を獲得する。失敗すると、1D6点のダメージを受ける。",
             "戦友\n一緒に敵と戦ううちに、絆が芽生えてくる。〔青春力〕で判定を行う。成功すると、ゲートにいるキャラクターの中から好きなものを一人選ぶ。自分とそのキャラクターは、お互いに対する《感情値》が1点上昇する（ゲートに誰がいるのかは、最終的にＧＭが決定すること）。失敗すると1D6点のダメージを受ける。",
             "援軍\nゲートには大量の敵が待ち構えていた。〔政治力〕のはんていを行う。成功すると、仲間が助けに来てくれて逃げ出すことができる。アイテムの【ポーション】を一つ獲得する。失敗すると、1D6点のダメージを受ける。",
             "罠\nゲートに仕掛けられた罠が発動する！〔学力〕で判定を行う。失敗すると、1D6点のダメージとランダムに選んだ変調一つを受ける。",
             "魔剣\n敵と戦う内に、武器の切れ味が鋭くなっている。〔学力〕で判定を行う。成功すると好きな武器一つを選ぶ。このセッションの間、威力が1点上昇する。失敗すると、1D6点のダメージを受ける。",
            ]
    getBreakTable(name, table)
  end


  def getBreakTable(name, table)
    number, dice_dmy = roll(2, 6)
    index = number - 2
    
    text = table[index]
    return '' if( text.nil? )
    
    return "#{name}休憩表(#{number}) #{ text }"
  end
  
  
  def getD6Table(name, table)
    number, dice_dmy = roll(1, 6)
    index = number - 1
    
    text = table[index]
    return '' if( text.nil? )
    
    return "#{name}(#{number}) #{ text }"
  end
  
  
  def getBattleFieldTable
    name = '戦場表'
    table = [
             "平地。\n特に特殊効果はない。",
             "罠。\n落とし穴やセキュリティー装置など、無数の罠が仕掛けられた戦場。この戦場にいるキャラクターは、ダメージを受けたとき、速度によるダメージ修整が2倍になる。",
             "障害物。\n林の中や狭い部屋の中など、自由に身動きすることが難しい戦場。この戦場にいるキャラクターは、プロットを行うとき、5以上の速度をプロットできなくなる。",
             "機動戦\n車や電車、船や飛行機など、動いているものの上での戦闘を表す。この戦場にいるキャラクターは、何らかの行為判定にファンブルした場合〔青春力〕で判定を行う。失敗すると、行動済みになり、速度が0になる。",
             "力場。\n展開や魔界の影響を強く受けている戦場。この戦場にいるキャラクターは、ラウンドの終了時に速度0にいると、〔学力〕の判定を行うことができる。成功すると、《アウル》を1点獲得できる。",
             "修羅場\n自分たちとは別の撃退士や天魔たちが戦闘を行っていたり、悪意に満ちた第三勢力に囲まれていたりする戦場。この戦場にいるキャラクターは、ラウンドの終了時に速度0にいると、〔政治力〕の判定を行う。失敗すると、《生命力》が1D6点減少する。",
            ]
    getD6Table(name, table)
  end

  def getFatalWoundsTable
    name = '致命傷表'
    table = [
             "圧倒的な攻撃が急所をつらぬく。\n行動不能になる。1D6ラウンド後の「ラウンドの終了時」に、まだ戦闘が継続しており、行動不能が回復していなければ、そのキャラクターは死亡する。",
             "昏睡し、身体中から血と生きる意志が失われていく。\n行動不能になる。また、この行動不能から回復した後、1D6を振り、ランダムに選んだ変調一つを受ける。",
             "大きな傷を負う。行動不能になる。",
             "凄まじい一撃に意識を失う。\n《生命力》が0点になり、行動不能になる。",
             "一瞬、気を失う。\n行動不能になる。1D6ラウンド後の「ラウンドの終了時」、もしくは、戦闘終了時に《生命力》が1点まで回復する（1D6ラウンドが経過するまでに、すでに《生命力》が1点以上に回復していた場合は、この効果は無効になる）。",
             "凄まじい幸運。\nそのシーンに自分に《好意》を持っているキャラクターがいたら、代わりにそのキャラクターがダメージを受けることができる（ダメージを代わりに受けるかどうかは、そのキャラクターを操るプレイヤー、もしくはGMが決定する）。誰もダメージを代わりに受けなかった場合、行動不能になる。",
             ]
    getD6Table(name, table)
  end
  
  def getFumbleTable
    name = 'ファンブル表'
    table = [
             "何もかもむなしくなる。誰かに対する《感情値》を1点減少する。",
             "あまりの失敗に心理的変調をきたす。1D6を振ってランダムに変調一つを選び、それを受ける。",
             "ポッキリと心が折れる。《アウル》を1点失う。",
             "あまりにも酷い大失敗を見られてしまい、周囲のキャラクターからの評価が変わる。自分の周囲に、自分に対して《感情値》を持つキャラクターがいたら、それを反転させる。",
             "敵の罠にかかる。自分の周りにいる、自分以外のすべての見方キャラクターは《生命力》を1D6点減少する。",
             "アウルが暴走して、大惨事に。自分の《生命力》を2D6点減少する。",
            ]
    getD6Table(name, table)
  end
  
  def getRandomNpcSchoolLife
    name = "学生生活関連ＮＰＣ表"
    
    table = [
      [11, "振り直し／任意"],
      [12, "大山恵（おおやま・めぐみ）：中等部3年0組：P84"],
      [13, "黒瀧辰馬（くろたき・たつま）：風紀委員長・大学部5年0組：P82"],
      [14, "シルヴァリティア・ドーン：大学部1年0組：P83"],
      [15, "岸崎蔵人（きしざき・くらんど）：大学部5年0組：P84"],
      [16, "レミエル・N・V：大学部2年0組：P83"],
      [22, "神楽坂茜（かぐらざか・あかね）：生徒会会長・高等部2年0組：P82"],
      [23, "炎條忍（えんじょう・しのぶ）：高等部1年0組：P83"],
      [24, "中山寧々美（なかやま・ねねみ）：新聞同好会会長・高等部3年0組：P83"],
      [25, "恵ヴィヴァルディ（めぐみ・−）：大学部2年0組：P83"],
      [26, "轟闘吾（とどろき・とうご）：高等部3年0組：P84"],
      [33, "鬼島武（きじま・たけし）：生徒会副会長・大学部1年0組：P82"],
      [34, "クリスティーナ・カーティス：大学部1年0組：P83"],
      [35, "潮崎紘乃（しおざき・ひろの）：依頼斡旋所受付：P84"],
      [36, "ライゼ：教師・寮長：P85"],
      [44, "大塔寺源九郎（だいとうじ・げんくろう）：生徒会書記・高等部3年0組：P82"],
      [45, "ストローベレー：用務員：P83"],
      [46, "竜崎アリス（りゅうざき・−）：オペレーター：P84"],
      [55, "大鳥南（おおとり・みなみ）：生徒会会計・高等部3年0組：P82"],
      [56, "筧鷹政（かけい・たかまさ）：OB：P83"],
      [66, "振り直し／任意"],
    ]
    
    return getRandomNpc(name, table)
  end
  
  def getRandomNpcOther
    name = "教師・その他ＮＰＣ表"
    
    table = [
      [11, "振り直し／任意"],
      [12, "月摘紫蝶（るつみ・しちょう）：教師：P84"],
      [13, "棄棄（すてき）：教師：P84"],
      [14, "遠野冴草（とおの・さえぐさ）：教師：P84"],
      [15, "速水風子（はやみ・ふうこ）：教師：P85"],
      [16, "アリス・ペンデルトン：教師：P85"],
      [22, "宝井正博（たからい・まさひろ）：学園長：P82"],
      [23, "白田悠里（しろた・ゆうり）：教師：P85"],
      [24, "常盤楓（ときわ・かえで）：教師：P85"],
      [25, "ダイナマ伊藤（−・いとう）：保健医：P85"],
      [26, "小日向千陰（おびなた・ちかげ）：教師・司書：P85"],
      [33, "ウーネミリア：悪魔：P114"],
      [34, "太珀（たいはく）：教師：P85"],
      [35, "神無月灯（みなづき・あかり）：ヴァニタス：P114"],
      [36, "キーヨ：ヴァニタス：P114"],
      [44, "マッド・ザ・クラウン：悪魔：P114"],
      [45, "劉玄盛（りゅう・げんせい）：シュトラッサー：P114"],
      [46, "厄蔵（やくぞう）：シュトラッサー：P114"],
      [55, "ギメル・ツァダイ：天使：P114"],
      [56, "ナターシャ：シュトラッサー：P114"],
      [66, "振り直し／任意"],
    ]

    return getRandomNpc(name, table)
  end
  
  def getRandomNpcDownClassmen
    name = "学生図鑑　下級学年表"
    
    table = [
      [11, "若菜白兎（わかな・しろう）：初等部2年2組：P72"],
      [12, "海原満月（かいばら・みづき）：初等部4年1組：P66"],
      [13, "雫（しずく）：初等部4年1組：P60"],
      [14, "相馬カズヤ（そうま・−）：初等部4年1組：P48"],
      [15, "廿九日神無（ひづめ・かんな）：初等部4年1組：P62"],
      [16, "カイン大澤（−・おおさわ）：初等部5年2組：P12"],
      [22, "機嶋結（きじま・ゆう）：初等部6年2組：P123"],
      [23, "静馬源一（しずま・げんいち）：初等部6年12組：P78"],
      [24, "花菱彪臥（はなびし・ひょうが）：中等部1年1組：P53"],
      [25, "天菱東希（てんびし・あずき）：中等部2年2組：P61"],
      [26, "御守陸（みもり・りく）：中等部2年2組：P51"],
      [33, "西園寺勇（さいおんじ・ゆう）：中等部2年3組：P47"],
      [34, "九条朔（くじょう・さく）：中等部3年1組：P77"],
      [35, "柴島華桜璃（くにじま・かおり）：中等部3年1組：P48"],
      [36, "唐沢完子（からさわ・かんこ）：中等部3年2組：P57"],
      [44, "雪成藤花（ゆきなり・とうか）：中等部3年2組：P53"],
      [45, "桐原雅（きりはら・みやび）：高等部1年1組：P18"],
      [46, "アイリス・L・橋場（−・るなくるす・はしば）：高等部1年11組：P79"],
      [55, "双星一（そうせい・はじめ）：高等部1年120組：P152"],
      [56, "影野恭弥（かげの・きょうや）：高等部2年2組：P78"],
      [66, "振り直し／任意"],
    ]

    return getRandomNpc(name, table)
  end
  
  def getRandomNpcUpperClassmen
    name = "学生図鑑　上級学年表"
    
    table = [
      [11, "下妻笹緒（しもつま・ささお）：高等部2年2組：P117"],
      [12, "ファティナ・Ｖ・アイゼンブルク（−・フォン・−）：高等部2年3組：P110"],
      [13, "姫川翔（ひめかわ・しょう）：高等部2年5組：P111"],
      [14, "イシュタル：高等部2年115組：P152"],
      [15, "小田切ルビィ（おだぎり・−）：高等部3年4組：P109"],
      [16, "大炊御門菫（おおいのみかど・すみれ）：高等部3年6組：P112"],
      [22, "朱頼天山楓（しゅらい・てんざん・かえで）：高等部3年114組：P152"],
      [23, "米流是武武（べるぜぶぶ）：高等部3年117組：P152"],
      [24, "麻生遊夜（あそう・ゆうや）：大学部1年1組：P122"],
      [25, "フィオナ・ボールドウィン：大学部1年1組：P79"],
      [26, "アデル・リーヴィス：大学部1年50組：P152"],
      [33, "エルディン：大学部1年50組：P152"],
      [34, "斐川幽夜（ひかわ・ももや）：大学部2年2組：P57"],
      [35, "ミハイル・エッカート：大学部2年4組：P122"],
      [36, "阿岳恭司（あたけ・きょうじ）：大学部2年9組：P119"],
      [44, "アンジェラ・アップルトン：大学部2年9組：P75"],
      [45, "アウリーエ・Ｆ・ダッチマン（−・フライング・−）：大学部3年50組：P152"],
      [46, "ジェディファ・エルクラステ：大学部3年50組：P152"],
      [55, "有田アリストテレス（ありた・−）：大学部4年6組：P69"],
      [56, "澄野絣（すみの・かすり）：大学部4年6組：P61"],
      [66, "振り直し／任意"],
    ]
    
    return getRandomNpc(name, table)
  end
  
  def getRandomNpc(name, table)
    number, result = get_table_by_d66_swap(table)
    return "#{name}(#{number}) #{result}"
  end
  
end
