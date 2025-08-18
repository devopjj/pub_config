# env.j

101
04.12: add CA from PIMA

JJ的工作環境設置。

- 2020.04.08: update from PIMA
- 2020.04.28: update from PIMA, at MacAirbook
- 2020.05.09: add init-env.sh
- 2020.05.20: remove .bash_alias , combine alias/export to **.commonrc** for bash/zsh
- 2020.10.04: transfer from 10.11.11.2 to 10.11.11.110

### ✅ 推荐结构说明（目标结构）

```
~/
├── .bashrc                     # 主入口，加载 .bashrc.d/ 下模块
├── .bash_profile              # 登录 shell 初始化（调用 .bashrc）
├── .bashrc.d/                 # 模块目录
│   ├── 00-env.sh              # 环境变量（含平台判断）
│   ├── 10-tools.sh            # 工具加载（pyenv, nvm, etc）
│   ├── 20-alias.sh            # alias 设置
│   ├── 30-func.sh             # 常用函数（来自 myfunc.sh）
│   └── 99-local.sh            # 用户自定义扩展
```
### git
#### 方案1: 手動控制同步目標
```
# 只推送到origin，讓GitHub Actions處理同步
git sync -r origin -m "update env config"

# 需要立即同步到github時
git sync -r github -m "urgent sync"
```


#### bash 自动安装脚本

```
bash <(curl -fsSL https://raw.githubusercontent.com/devopjj/pub_config/refs/heads/master/install-bashrc.sh)
```
#### ops-toolkis
只讀拉取
PAT_READONLY="XXX"
owner="devopjj"
repo="ops-toolkit"
git clone https://devopjj:$PAT_READONLY@github.com/${owner}/${repo}.git

### .bash_profile

- .myfuncrc：發送訊息 `sendslack  jim test`

### PIMA

1. `/data/nm/` 是公用的網管區。
2. `Source`: **/nmdata** ->**/NAS/nmdata/**
3. `.rc配置`皆 以 symbolink 至 /home/jim/gitrepo/env.j, 直接以git進行維護更新。

```sh
.bashrc -> gitrepo/env.j/.bashrc
.cshrc -> gitrepo/env.j/.cshrc
.screenrc -> gitrepo/env.j/.screenrc
.vimrc -> gitrepo/env.j/.vimrc
.vim -> gitrepo/env.j/.vim
.wgetrc -> gitrepo/env.j/.wgetrc
.tmux.conf -> gitrepo/env.j/.tmux.conf
myfunc.sh -> gitrepo/env.j/myfunc.sh
.commonrc->-> gitrepo/env.j/.commonrc
```

4. `ssh key`:`~jim/.private.j/key` symoblink `/NAS/cloud/JJ-Sec/id_rsa_2048_key`

### 通用設定

1. ~jim/env.j/.\*rc
2. ~jim/env.j/.ssh/

### rsync

1. SSH private key存放於：/NAS/cloud/JJ-Sec/id_rsa_2048_key/，与授权PC进行同步。
2. id_rsa key 同步只能使用 `rsync`一次性下戴回本機端。

### PIMA以外的用法

~~rc link : symbolic `~jim/env.j/.rc`~~

#### 1.下載檔案

```sh
cd ~
~ git clone http://git.jj.me/cdim/env.j.git~
第一次下戴：git clone http://git.jj.me/cdim/env.j.git
修改git repo:
vi ~/env.j/.git/config

```

#### 2.符號連結

```
env.j/init-env.sh
```

#### 3. ssh key ：rsync 至 `~jim/.private.j/`

```sh
rsync -av4 --delete -e 'ssh' jim@10.11.11.2:/NAS/cloud/SyncJJ/JJ-Sec/id_rsa_2048_key/ ~/.private.j```
```
