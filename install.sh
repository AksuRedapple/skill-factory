#!/bin/zsh
# install.sh — skill 工厂安装器（配置驱动）
# 从 agents.conf 读取 agent 路径，从 publish.map 读取分发关系，按注册表建软链。
# 注意：需 zsh（用了关联数组）。
#
# 用法：
#   ./install.sh <skill-name> [--agent <agent>]   # 安装单个 skill
#   ./install.sh --all [--agent <agent>]          # 安装所有 skill
#   ./install.sh --list                           # 列出所有 skill 及安装状态

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_CONF="$SCRIPT_DIR/agents.conf"
PUBLISH_MAP="$SCRIPT_DIR/publish.map"

# 1. 从 agents.conf 读取 agent → skills 目录映射（配置驱动，不硬编码）
declare -A AGENT_DIRS
parse_agents_conf() {
  [[ -f "$AGENTS_CONF" ]] || { echo "❌ 缺少 agents.conf（可从 agents.conf.example 复制）"; exit 1; }
  while IFS='=' read -r name path || [[ -n "$name" ]]; do
    [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
    name="${name## }"; name="${name%% }"
    path="${path## }"; path="${path%% }"
    path="${path/#\$HOME/$HOME}"          # 展开 $HOME
    AGENT_DIRS[$name]="$path"
  done < "$AGENTS_CONF"
}
parse_agents_conf

# 2. 解析 publish.map（skill名=项目路径|目标agent）
declare -A SKILL_PROJECTS
declare -A SKILL_TARGETS
parse_publish_map() {
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key="${key## }"; key="${key%% }"; key="${key//\"/}"
    value="${value## }"; value="${value%% }"
    if [[ "$value" == *"|"* ]]; then
      local parts=("${(@s/|/)value}")
      SKILL_PROJECTS[$key]="${parts[1]}"
      SKILL_TARGETS[$key]="${parts[2]}"
    else
      SKILL_PROJECTS[$key]="$key"
      SKILL_TARGETS[$key]="$value"
    fi
  done < "$PUBLISH_MAP"
}
parse_publish_map

resolve_skill_dir() {
  local project="${SKILL_PROJECTS[$1]}"
  # 支持绝对路径（skill 可在工厂外）与相对路径（相对工厂根）
  if [[ "$project" = /* ]]; then echo "$project"; else echo "$REPO_DIR/$project"; fi
}

get_targets_array() {
  local targets_str="${SKILL_TARGETS[$1]}"
  if [[ "$targets_str" == "all" ]]; then
    echo "${(k)AGENT_DIRS[@]}"
  else
    echo "${targets_str//,/ }" | tr -d '"' | xargs
  fi
}

install_publish() {
  local publish_name="${1//\"/}"
  local agent="${2//\"/}"
  local skill_dir="$(resolve_skill_dir "$publish_name")"
  local target_dir="${AGENT_DIRS[$agent]}"
  [[ -z "$target_dir" ]] && { echo "❌ 未知 agent: $agent（检查 agents.conf）"; return 1; }

  # 优先 dist/（构建模式），否则链源码根目录（直链模式）
  local source_path="$skill_dir/dist/$publish_name"
  [[ -d "$source_path" ]] || source_path="$skill_dir"
  [[ -d "$source_path" ]] || { echo "⚠️  源目录不存在，跳过: $source_path"; return 0; }

  mkdir -p "$target_dir"
  # 已存在且非软链 → 备份
  if [[ -e "$target_dir/$publish_name" && ! -L "$target_dir/$publish_name" ]]; then
    mv "$target_dir/$publish_name" "$target_dir/${publish_name}.bak.$(date +%Y%m%d%H%M%S)"
    echo "⚠️  已备份原目录: $target_dir/${publish_name}.bak.*"
  fi
  rm -f "$target_dir/$publish_name"
  ln -s "$source_path" "$target_dir/$publish_name"
  echo "✅ [$agent] $publish_name → $source_path"
}

install_skill_by_name() {
  local skill_name="$1" target_agent="$2" found=false
  for publish_name in ${(k)SKILL_PROJECTS[@]}; do
    publish_name="${publish_name//\"/}"
    local base_name="$(basename "${SKILL_PROJECTS[$publish_name]}")"
    if [[ "$publish_name" == "$skill_name" || "$base_name" == "$skill_name" ]]; then
      found=true
      local -a agents_arr=(${(s/ /)"$(get_targets_array "$publish_name")"})
      for agent in "${agents_arr[@]}"; do
        [[ "$target_agent" != "default" && "$agent" != "$target_agent" ]] && continue
        install_publish "$publish_name" "$agent"
      done
    fi
  done
  $found || { echo "❌ 未找到 skill: $skill_name"; echo "   可用: ${(k)SKILL_PROJECTS[@]}"; return 1; }
}

list_skills() {
  echo "📦 skill 工厂：$REPO_DIR"
  echo ""
  printf "%-25s %-25s %-20s %s\n" "发布名" "项目路径" "目标 AGENTS" "安装状态"
  printf "%-25s %-25s %-20s %s\n" "-------" "--------" "-------------" "--------"
  for publish_name in ${(ko)${(k)SKILL_PROJECTS}}; do
    publish_name="${publish_name//\"/}"
    local project="${SKILL_PROJECTS[$publish_name]}" targets="${SKILL_TARGETS[$publish_name]}" install_status=""
    for agent in ${(s/ /)"$(get_targets_array "$publish_name")"}; do
      [[ -L "${AGENT_DIRS[$agent]}/$publish_name" ]] && install_status+="$agent "
    done
    [[ -z "$install_status" ]] && install_status="未安装"
    printf "%-25s %-25s %-20s %s\n" "$publish_name" "$project" "$targets" "$install_status"
  done
}

# 参数解析
SKILL="" TARGET_AGENT="default" INSTALL_ALL=false LIST_MODE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) INSTALL_ALL=true; shift ;;
    --list) LIST_MODE=true; shift ;;
    --agent) TARGET_AGENT="$2"; shift 2 ;;
    -*) echo "未知参数: $1"; exit 1 ;;
    *) SKILL="$1"; shift ;;
  esac
done

$LIST_MODE && { list_skills; exit 0; }
if $INSTALL_ALL; then
  echo "🚀 安装所有 skill..."
  for publish_name in ${(k)SKILL_PROJECTS[@]}; do
    install_skill_by_name "${publish_name//\"/}" "$TARGET_AGENT"
  done
  echo ""; echo "✨ 全部安装完成"; exit 0
fi
[[ -n "$SKILL" ]] && { install_skill_by_name "$SKILL" "$TARGET_AGENT"; exit 0; }

echo "用法："
echo "  ./install.sh <skill-name> [--agent <agent>]"
echo "  ./install.sh --all [--agent <agent>]"
echo "  ./install.sh --list"
echo ""
echo "已配置 agent: ${(k)AGENT_DIRS[@]}"
