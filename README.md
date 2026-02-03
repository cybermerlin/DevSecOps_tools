# DevSecOps tools

*@author's channel: ✈️ https://t.me/cybermerlin_pub*

Hand made (and AI-made ;-) tools to simplify some works for IT-engineers (and me).

## TODO

- [x] add tests by `shellcheck`
- [ ] look at the **pnetlab**
- [ ] compare and get choice ansible, vagrant, chef, puppet, ... **(need sync pipelining + control /etc changes n syncing + quick restore \ installation on all srv)** <etckeeper,argoCD,secretVault>
- [ ] tests:


## 🧪 Фреймворки для тестирования shell-скриптов

### 1. **Bats (Bash Automated Testing System)**

```bash
#!/usr/bin/env bats

@test "test file creation" {
    run ./my_script.sh
    [ "$status" -eq 0 ]
    [ -f "/tmp/testfile" ]
}

@test "test with input" {
    run bash -c 'echo "input" | ./my_script.sh'
    [ "$output" = "expected output" ]
}
```

### 2. **ShellSpec**

```bash
Describe 'My script'
  It 'creates file'
    When run script my_script.sh
    The status should be success
    The file "/tmp/testfile" should be exist
  End
End
```

## 📊 Инструменты для покрытия кода

### 1. **kcov**

```bash
# Установка
sudo apt-get install kcov

# Запуск
kcov --coveralls-id=$TRAVIS_JOB_ID coverage ./my_script.sh

# HTML отчет в coverage/
```


### 2. **BashCover**

```bash
git clone https://github.com/mikefarah/bashcover
cd bashcover
./bashcover test_script.sh
```

## 🔍 Статический анализ и безопасность

### 1. **ShellCheck** (обязательный инструмент!)

```bash
# Установка
sudo apt-get install shellcheck

# Использование
shellcheck my_script.sh
shellcheck -s bash -x *.sh  # для bash с проверкой внешних команд

# Интеграция с pre-commit
# .pre-commit-config.yaml:
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks:
      - id: shellcheck
```


### 2. **shfmt** (форматирование)

```bash
# Форматирование кода
shfmt -w my_script.sh

# Проверка стиля
shfmt -d my_script.sh
```

### 3. **Bashate** (проверка стиля)

```bash
pip install bashate
bashate my_script.sh
```

## 🛡️ Сканирование на уязвимости

### 1. **Lynis** (аудит безопасности)

```bash
git clone https://github.com/CISOfy/lynis
cd lynis
./lynis audit system
```

### 2. **TruffleHog** (поиск секретов)

```bash
# Поиск в git истории
docker run --rm -v "$PWD":/workdir trufflesecurity/trufflehog:latest git file:///workdir --only-verified

# Локальные файлы
trufflehog filesystem /path/to/scripts
```

### 3. **Gitleaks**

```bash
# Сканирование git репозитория
gitleaks detect --source /path/to/repo --verbose

# Pre-commit хук
pre-commit install
pre-commit run gitleaks
```

## 📈 Системы отчетности

### 1. **Custom reporting with JUnit**

```bash
# В тестах bats с плагином bats-junit
bats --formatter junit test/ > test-results.xml

# Интеграция в CI (GitLab пример)
test:
  stage: test
  script:
    - bats --formatter junit test/ > test-results.xml
  artifacts:
    reports:
      junit: test-results.xml
```

### 2. **Allure Framework**

```bash
# Генерация красивых отчетов
pytest --alluredir=allure-results
allure serve allure-results
```

## 🎯 Готовые решения CI/CD

### 1. **GitHub Actions workflow**

```yaml
name: Shell Script CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: ShellCheck
        uses: azohra/shell-linter@latest
      - name: Run tests
        run: |
          sudo apt-get install bats
          bats test/
      - name: Security scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
```

### 2. **GitLab CI**

```yaml
stages:
  - test
  - security

shellcheck:
  stage: test
  script:
    - shellcheck *.sh

unit_tests:
  stage: test
  script:
    - apt-get update && apt-get install -y bats
    - bats test/

security_scan:
  stage: security
  image: trufflesecurity/trufflehog:latest
  script:
    - trufflehog git file://$CI_PROJECT_DIR --only-verified
```

## 🔧 Рекомендуемый стек для проекта

### Базовый набор (обязательно)

```bash
# pre-commit-config.yaml
repos:
  - repo: https://github.com/koalaman/shellcheck-precommit
    rev: v0.9.0
    hooks: [{id: shellcheck}]
  
  - repo: https://github.com/mvdan/shfmt-precommit
    rev: v0.1.0
    hooks: [{id: shfmt}]
  
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks: [{id: gitleaks}]
```

# 0 end

- [ ] sh + py - test

# 1

## 🎯 Универсальные инструменты для обоих языков

### 1. **CI/CD системы** (общие)

```yaml
# GitHub Actions .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Python
        uses: actions/setup-python@v4
        with: {python-version: '3.x'}
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run Shell tests
        run: |
          sudo apt-get install -y shellcheck bats
          make test-shell
      - name: Run Python tests
        run: make test-python
```

### 2. **Контейнеризация** (Docker)

```dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    shellcheck \
    bats \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

CMD ["make", "test-all"]
```

## 🐚 Инструменты для Shell-скриптов

### 1. **Тестирование**

```bash
# Makefile
test-shell:
	shellcheck scripts/*.sh
	bats tests/shell/
	shfmt -d scripts/

coverage-shell:
	kcov --include-pattern=.sh coverage/ ./run-tests.sh
```

### 2. **Bats тесты с фикстурами**

```bash
#!/usr/bin/env bats
# tests/shell/file_processor.bats

setup() {
    export TEST_DIR="/tmp/test_$$"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "process files correctly" {
    echo "test" > "$TEST_DIR/input.txt"
    run ./scripts/processor.sh "$TEST_DIR/input.txt"
    [ "$status" -eq 0 ]
    [ -f "$TEST_DIR/output.txt" ]
}
```

### 3. **Мониторинг выполнения**

```bash
#!/bin/bash
# scripts/security_monitor.sh

monitor_script() {
    local script=$1
    # Логирование вызовов
    strace -f -e trace=network,process -o "/tmp/trace_$$.log" "$script"
    
    # Мониторинг ресурсов
    /usr/bin/time -v "$script" 2> "/tmp/resources_$$.log"
}
```

## 🐍 Инструменты для Python-скриптов

### 1. **Тестирование**

```python
# pytest с покрытием
# requirements-test.txt
pytest>=7.0.0
pytest-cov
pytest-mock
pytest-asyncio

# tests/python/test_processor.py
import pytest
import subprocess
from my_module import Processor

class TestProcessor:
    def test_integration_with_shell(self, tmp_path):
        # Интеграция shell + Python
        result = subprocess.run(
            ["./scripts/preprocessor.sh", str(tmp_path)],
            capture_output=True, text=True, check=True
        )
        assert result.returncode == 0
        
        # Python тест
        processor = Processor(tmp_path)
        assert processor.validate()
```

### 2. **Статический анализ Python**

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: https://github.com/psf/black
    rev: 23.3.0
    hooks: [{id: black}]

  - repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks: [{id: flake8}]

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks: [{id: isort}]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.3.0
    hooks: [{id: mypy}]
```

## 🔒 Безопасность для обоих языков

### 1. **Сканирование секретов**

```yaml
# .gitleaks.toml
title = "gitleaks config"

[[rules]]
description = "AWS Access Key ID"
regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
tags = ["key", "AWS"]

[[rules]]
description = "Shell injection patterns"
regex = '''(eval\s+|\|\s*bash|\$\{.*\})'''
tags = ["injection", "shell"]
```

### 2. **Security сканеры**

```bash
# Bandit для Python
bandit -r my_package/ -f json -o bandit-report.json

# Safety для зависимостей
safety check -r requirements.txt --json

# Trivy для контейнеров и зависимостей
trivy filesystem --security-checks vuln,secret,config .
```

## 📊 Унифицированная отчетность

### 1. **Объединенные отчеты**

```python
# scripts/generate_report.py
import json
import xml.etree.ElementTree as ET
from datetime import datetime

def combine_reports():
    reports = {
        "timestamp": datetime.now().isoformat(),
        "shell": parse_shell_results(),
        "python": parse_python_results(),
        "security": parse_security_results()
    }
    
    with open("combined-report.json", "w") as f:
        json.dump(reports, f, indent=2)

def generate_html_dashboard():
    # Генерация единого дашборда
    pass
```

### 2. **Allure отчеты**

```yaml
# allure.yml
plugins:
  - junit-xml-plugin
  - xunit-xml-plugin
  - trx-plugin
  - behaviors-plugin

# Запуск тестов с генерацией отчетов
allure-python: |
  pytest --alluredir=allure-results/python tests/python/
allure-shell: |
  bats --formatter junit tests/shell/ > allure-results/shell/bats-results.xml
```

## 🏗️ Готовая конфигурация проекта

### **Makefile**

```makefile
.PHONY: test-all test-shell test-python security coverage clean

test-all: test-shell test-python security

test-shell:
	@echo "=== Shell Script Testing ==="
	shellcheck scripts/*.sh
	shfmt -d scripts/
	bats --tap tests/shell/

test-python:
	@echo "=== Python Testing ==="
	black --check src/ tests/python/
	flake8 src/ tests/python/
	mypy src/
	pytest tests/python/ -v --cov=src --cov-report=html:coverage/python

security:
	@echo "=== Security Scanning ==="
	gitleaks detect --source . -v
	bandit -r src/ -f json
	trufflehog filesystem . --only-verified

coverage:
	kcov --include-pattern=.sh coverage/shell/ ./run-shell-tests.sh
	pytest --cov=src --cov-report=html:coverage/python tests/python/

clean:
	rm -rf coverage/ allure-results/ .pytest_cache/ .mypy_cache/
```

### **Docker для тестирования**
```dockerfile
FROM python:3.11-slim

# Установка инструментов для shell
RUN apt-get update && apt-get install -y \
    shellcheck \
    bats \
    kcov \
    make \
    && rm -rf /var/lib/apt/lists/*

# Установка Python инструментов
COPY requirements.txt requirements-test.txt .
RUN pip install -r requirements.txt -r requirements-test.txt

WORKDIR /app
COPY . .

CMD ["make", "test-all"]
```

## 🚀 CI/CD пайплайн

### **GitHub Actions**
```yaml
name: Shell & Python CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.9, 3.10, 3.11]

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with: {python-version: ${{ matrix.python-version }}}
    
    - name: Install system dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y shellcheck bats kcov
    
    - name: Install Python dependencies
      run: pip install -r requirements.txt -r requirements-test.txt
    
    - name: Run Shell tests
      run: make test-shell
    
    - name: Run Python tests
      run: make test-python
    
    - name: Security scan
      run: make security
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/python/coverage.xml
        flags: python
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      with:
        name: test-results
        path: |
          allure-results/
          coverage/
```

# 1 end

- [ ] Checkov

# 2

## 🔍 **Checkov - Static Analysis for IaC**

### **Что такое Checkov?**
Checkov - это статический анализатор кода для проверки шаблонов облачной инфраструктуры на безопасность и соответствие best practices.

**Поддерживаемые форматы:**
- Terraform (tf, tf.json)
- CloudFormation (YAML, JSON)
- Kubernetes (YAML, Helm)
- Dockerfile
- ARM Templates
- Ansible
- Bicep
- OpenAPI

### 🚀 **Быстрый старт**

```bash
# Установка
pip install checkov

# Базовая проверка
checkov -d /path/to/your/code

# Проверка конкретного файла
checkov -f deployment.yaml

# Проверка с выходом в JSON
checkov -d . --output json

# Проверка только определенных политик
checkov -d . --check CKV_AWS_19,CKV_AWS_20
```

### ⚙️ **Интеграция с CI/CD**

#### **GitHub Actions**
```yaml
name: Checkov Security Scan
on: [push, pull_request]

jobs:
  checkov:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform
          output_format: sarif
          output_file_path: results.sarif
```

#### **GitLab CI**
```yaml
stages:
  - security

checkov:
  stage: security
  image:
    name: bridgecrew/checkov:latest
    entrypoint: [""]
  script:
    - checkov -d . --soft-fail
  artifacts:
    reports:
      sast: gl-sast-report.json
```

### 🛡️ **Примеры проверок**

#### **Terraform**
```hcl
# Проверяемый файл: main.tf
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  # Checkov обнаружит: CKV_AWS_18 - S3 bucket should have logging enabled
  # CKV_AWS_21 - S3 bucket should have versioning enabled
}

resource "aws_security_group" "allow_all" {
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # CKV_AWS_23 - Security group allows all traffic
  }
}
```

#### **Kubernetes**
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: nginx:latest  # CKV_K8S_10 - Image tag should be fixed
        securityContext:
          runAsUser: 0  # CKV_K8S_21 - Should not run as root
        resources: {}  # CKV_K8S_11 - CPU limits should be set
```

#### **Dockerfile**
```dockerfile
FROM ubuntu:latest  # CKV_DOCKER_10 - Base image should have tag
USER root  # CKV_DOCKER_2 - Should not run as root
ADD . /app  # CKV_DOCKER_4 - Avoid using ADD
```

### 📊 **Конфигурация и кастомизация**

#### **.checkov.yaml**
```yaml
# Конфигурационный файл Checkov
branch: main
download-external-modules: true
evaluate-variables: true
external-modules-download-path: .external_modules
framework:
  - terraform
  - cloudformation
  - kubernetes
skip-checks:
  - CKV_AWS_115 # Lambda function should have DLQ configured
  - CKV_AWS_111 # IAM policies should not allow * resource
quiet: false
soft-fail: false
use-enforcement-rules: false
```

#### **Подавление предупреждений**
```python
# В коде Terraform
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  # checkov:skip=CKV_AWS_18: logging not required for this test bucket
  # checkov:skip=CKV_AWS_21: versioning not needed
}
```

### 🔧 **Расширенные возможности**

#### **Пользовательские политики**
```python
# custom_policy.py
from checkov.common.models.enums import CheckResult, CheckCategories
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

class S3BucketEncryptionCheck(BaseResourceCheck):
    def __init__(self):
        name = "Ensure S3 bucket has encryption enabled"
        id = "CUSTOM_AWS_001"
        categories = [CheckCategories.ENCRYPTION]
        supported_resources = ['aws_s3_bucket']
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        if 'server_side_encryption_configuration' in conf:
            return CheckResult.PASSED
        return CheckResult.FAILED

scanner = S3BucketEncryptionCheck()
```

#### **Интеграция с мониторингом**
```bash
# Непрерывный мониторинг
checkov -d . --bc-api-key $BC_API_KEY --repo-id my-org/my-repo

# Периодические проверки
#!/bin/bash
# security_scan.sh
while true; do
    checkov -d /opt/infrastructure --soft-fail
    if [ $? -ne 0 ]; then
        echo "Security issues found!" | mail -s "Checkov Alert" admin@company.com
    fi
    sleep 3600  # Проверка каждый час
done
```

### 📈 **Отчетность и мониторинг**

```bash
# Различные форматы вывода
checkov -d . --output json
checkov -d . --output junitxml
checkov -d . --output sarif
checkov -d . --output cyclonedx

# Создание HTML отчета
checkov -d . --output json | python -c "
import json, sys
data = json.load(sys.stdin)
print(f'Total checks: {data[\"summary\"][\"failed\"] + data[\"summary\"][\"passed\"]}')
print(f'Failed: {data[\"summary\"][\"failed\"]}')
"

# Интеграция с Bridgecrew платформой
checkov -d . --bc-api-key $BC_API_KEY --repo-id my-repo --branch main
```

### 🎯 **Практические примеры использования**

#### **Для Terraform проектов**
```bash
# Полная проверка Terraform
checkov -d terraform/ --framework terraform

# Проверка только определенных директорий
checkov -d terraform/modules/networking --framework terraform

# С исключением определенных проверок
checkov -d . --skip-check CKV_AWS_115,CKV_AWS_111
```

#### **Для Kubernetes**
```bash
# Проверка всех YAML файлов
checkov -d k8s/ --framework kubernetes

# Проверка Helm charts
checkov -d charts/ --framework kubernetes
```

#### **Мониторинг в реальном времени**
```python
#!/usr/bin/env python3
# checkov_watcher.py
import time
import subprocess
import json
from pathlib import Path

def monitor_infrastructure():
    path = Path("/opt/infrastructure")
    while True:
        result = subprocess.run(
            ["checkov", "-d", str(path), "--output", "json"],
            capture_output=True, text=True
        )
        
        if result.returncode != 0:
            report = json.loads(result.stdout)
            failed_checks = report["summary"]["failed"]
            print(f"🚨 Found {failed_checks} security issues!")
            
        time.sleep(300)  # Проверка каждые 5 минут

if __name__ == "__main__":
    monitor_infrastructure()
```

## Structure

- run.sh - main execution script (cli menu)
- [x] [cleaner](cleaner/README.md) to cleanup Ubuntu
- [x] [common](common) common scripts used across current project
  - colors.sh - color output utilities
  - handler.sh - common handler functions
  - progress.sh - progress indication utilities
- [x] **GOAL.0** [dev-prep](dev-prep/README.md) to install base dev software
  - [x] [docker-inst](dev-prep/docker-inst/README.md) to install docker (and possibilities to remove it or stop)
  - [x] [windsurf](dev-prep/windsurf/README.md) to install Windsurf IDE on WSL-Ubuntu
- [ ] [generators](generators/README.md) test and script generators from Gherkins specs
- [ ] **GOAL.2** [monitor](monitor/README.md) scripts to monitor and manage * activities on the server and dev.host
  - [ ] [quota disk | alert](disk/README.md) activities
  - [ ] [disk IO](disk/README.md) activities
  - [ ] [network](network/README.md) activities
- [ ] **GOAL.1** [registry](registry/) scripts to setup and using a Registry to cache all downloaded packages (apt, docker, nodejs, mvn,...)
- [secrets](secrets/) all your secrects should be there to do not be saved in cur git project
- [test](test/) all tests of this project
- [ ] [VPN](vpn/) prepare and using VPN
- [ ] [windows 11](win11/README.md) scripts for windows 11
- [-] [wsl-prep](wsl-prep/README.md) to prepare Ubuntu under WSL and upgrade
- [ ] [ci/cd srv](cicd/README.md) prepare CI/CD srv and another dev servers (artifact-repo, QA, ...)
- [ ] git/hooks to use cid/cd pipeline before commit-push and after release
- [ ] [web proj maker](web-maker/README.md) scripts to make a new Web project to simplify dev.job
- [x] run.sh - to run all scripts through the Menu or through a cli
- [x] sync.sh - to sync all changes of scripts of this project between you host and wsl-machine, and git-repo


## Tests

All scripts should be covered by tests:

- for shell-scripts we use shellcheck first ![screenshot shellcheck wrapper](shellchecker_out.png)
- for any-scripts in second we use self-wrote tests (actually by an algorithm from gherkin-description)
- in 3rd, all-scripts should be checked by sonar (or other alternatives of static and dynamic code-analyzer)


## For Windows engineers

Use (if your source directory like mine or change it):
```sh
mkdir -p ~/dev/admin && time sudo rsync -av --delete-after --delete-excluded /mnt/f/dev/projects/admin/cleanup/DevSecOps_tools ~/dev/admin/ && cd ~/dev/admin/DevSecOps_tools && sudo chown -R user:user . && ./common/chmod-x.sh >/dev/null

./run.sh
```

For me, to sync changes from WSL to Win-host: `time sudo rsync -av --delete-after --delete-excluded ../DevSecOps_tools /mnt/f/dev/projects/admin/cleanup/`
