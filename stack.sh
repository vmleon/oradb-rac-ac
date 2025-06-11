#!/bin/bash

# Simple monitoring stack management
# One script for setup, monitoring, and cleanup

set -e

show_help() {
    cat << 'EOF'
📊 Monitoring Stack Manager
===========================

Usage: ./stack.sh <command>

Commands:
  setup     Start Prometheus and Grafana containers
  status    Show current status of monitoring stack  
  cleanup   Stop containers and optionally remove data
  help      Show this help

Examples:
  ./stack.sh setup     # Start monitoring
  ./stack.sh status    # Check what's running
  ./stack.sh cleanup   # Stop and clean up

Quick start:
1. ./stack.sh setup
2. ./gradlew run (in another terminal)
3. Open http://localhost:9090 (Prometheus)
4. Open http://localhost:3000 (Grafana, admin/admin)
EOF
}

setup_monitoring() {
    echo "🚀 Setting up monitoring stack"
    echo "=============================="
    
    # Check for existing containers
    if podman ps -a --format "{{.Names}}" | grep -E "^(prometheus|grafana)$" > /dev/null 2>&1; then
        echo "❌ Monitoring containers already exist"
        echo "   Run: ./stack.sh cleanup"
        exit 1
    fi
    
    # Check for required config file
    if [[ ! -f "config/prometheus/prometheus.yml" ]]; then
        echo "❌ config/prometheus/prometheus.yml not found"
        echo "   Please create prometheus.yml in config/prometheus/ before running setup"
        exit 1
    fi
    
    echo "✅ Using existing config/prometheus/prometheus.yml configuration"
    
    echo "📊 Setting up dashboard and datasource provisioning"
    
    # Create data directories
    echo "📁 Setting up data directories..."
    mkdir -p ./data/{prometheus,grafana}
    chmod 777 ./data/grafana
    chmod 755 ./data/prometheus
    
    # Create dashboard provisioning config
    echo "📁 Setting up dashboard provisioning config..."
    mkdir -p ./data/grafana-config
    cat > ./data/grafana-config/dashboards.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF
    
    # Start Prometheus
    echo "🎯 Starting Prometheus..."
    podman run -d \
        --name prometheus \
        -p 9090:9090 \
        -v "$(pwd)/config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro" \
        -v "$(pwd)/data/prometheus:/prometheus" \
        prom/prometheus:latest \
        --config.file=/etc/prometheus/prometheus.yml \
        --storage.tsdb.path=/prometheus \
        --storage.tsdb.retention.time=15d \
        --web.enable-lifecycle
    
    # Start Grafana with direct file mounting
    echo "🎨 Starting Grafana..."
    podman run -d \
        --name grafana \
        -p 3000:3000 \
        -v "$(pwd)/data/grafana:/var/lib/grafana" \
        -v "$(pwd)/config/grafana/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml:ro" \
        -v "$(pwd)/config/grafana/dashboard.json:/etc/grafana/provisioning/dashboards/dashboard.json:ro" \
        -v "$(pwd)/data/grafana-config/dashboards.yml:/etc/grafana/provisioning/dashboards/dashboards.yml:ro" \
        -e "GF_SECURITY_ADMIN_PASSWORD=admin" \
        -e "GF_USERS_ALLOW_SIGN_UP=false" \
        grafana/grafana:latest
    
    # Wait and verify
    echo "⏳ Waiting for services to start..."
    sleep 15
    
    # Quick health check
    local prometheus_ok=false
    local grafana_ok=false
    
    if curl -s http://127.0.0.1:9090/-/healthy > /dev/null 2>&1; then
        prometheus_ok=true
    fi
    
    if curl -s http://127.0.0.1:3000/api/health > /dev/null 2>&1; then
        grafana_ok=true
    fi
    
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "📊 Services:"
    if $prometheus_ok; then
        echo "  ✅ Prometheus: http://localhost:9090"
    else
        echo "  ⏳ Prometheus: http://localhost:9090 (still starting)"
    fi
    
    if $grafana_ok; then
        echo "  ✅ Grafana: http://localhost:3000 (admin/admin)"
    else
        echo "  ⏳ Grafana: http://localhost:3000 (still starting)"
    fi
    
    echo ""
    echo "📋 Next steps:"
    echo "1. Start your Java app: ./gradlew run"
    echo "2. Check status: ./stack.sh status"
    echo "3. In Grafana, add Prometheus datasource: http://localhost:9090"
    echo ""
    echo "💡 Note: Prometheus will use the configuration in config/prometheus/prometheus.yml"
    
    echo "📊 Dashboard automatically loaded from dashboard.json"
    echo "🔗 Datasource automatically configured from datasource.yml"
}


show_status() {
    echo "📊 Monitoring Stack Status"
    echo "=========================="
    echo ""
    
    # Container status with more detail
    echo "🐳 Containers:"
    local prometheus_running=false
    local grafana_running=false
    
    if podman ps --format "{{.Names}}" | grep -E "^prometheus$" > /dev/null 2>&1; then
        prometheus_running=true
        local prom_status=$(podman ps --format "{{.Status}}" --filter "name=prometheus")
        echo "  ✅ prometheus ($prom_status)"
    elif podman ps -a --format "{{.Names}}" | grep -E "^prometheus$" > /dev/null 2>&1; then
        local prom_status=$(podman ps -a --format "{{.Status}}" --filter "name=prometheus")
        echo "  ⏹️  prometheus ($prom_status)"
    else
        echo "  ❌ prometheus (not found)"
    fi
    
    if podman ps --format "{{.Names}}" | grep -E "^grafana$" > /dev/null 2>&1; then
        grafana_running=true
        local grafana_status=$(podman ps --format "{{.Status}}" --filter "name=grafana")
        echo "  ✅ grafana ($grafana_status)"
    elif podman ps -a --format "{{.Names}}" | grep -E "^grafana$" > /dev/null 2>&1; then
        local grafana_status=$(podman ps -a --format "{{.Status}}" --filter "name=grafana")
        echo "  ⏹️  grafana ($grafana_status)"
    else
        echo "  ❌ grafana (not found)"
    fi
    
    echo ""
    
    # Service health with better startup detection
    echo "🌐 Services:"
    
    if ! command -v curl > /dev/null 2>&1; then
        echo "  ❌ curl not available - cannot test service health"
        echo ""
    else
        # Test Prometheus
        if $prometheus_running; then
            local prom_status=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9090/-/healthy 2>/dev/null || echo "000")
            if [[ "$prom_status" == "000" ]]; then
                # Try IPv6 if IPv4 failed
                prom_status=$(curl -s -o /dev/null -w "%{http_code}" http://[::1]:9090/-/healthy 2>/dev/null || echo "000")
            fi
            
            if [[ "$prom_status" == "200" ]]; then
                echo "  ✅ Prometheus: http://localhost:9090 (healthy)"
            elif [[ "$prom_status" == "000" ]]; then
                echo "  ⏳ Prometheus: http://localhost:9090 (container running, service not ready)"
                echo "     Service is still starting up inside container"
            else
                echo "  ⚠️  Prometheus: http://localhost:9090 (HTTP $prom_status)"
            fi
        else
            echo "  ❌ Prometheus: container not running"
        fi
        
        # Test Grafana
        if $grafana_running; then
            local grafana_status=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health 2>/dev/null || echo "000")
            if [[ "$grafana_status" == "000" ]]; then
                # Try IPv6 if IPv4 failed
                grafana_status=$(curl -s -o /dev/null -w "%{http_code}" http://[::1]:3000/api/health 2>/dev/null || echo "000")
            fi
            
            if [[ "$grafana_status" == "200" ]]; then
                echo "  ✅ Grafana: http://localhost:3000 (healthy)"
            elif [[ "$grafana_status" == "000" ]]; then
                echo "  ⏳ Grafana: http://localhost:3000 (container running, service not ready)"
                echo "     Service is still starting up inside container"
            else
                echo "  ⚠️  Grafana: http://localhost:3000 (HTTP $grafana_status)"
            fi
        else
            echo "  ❌ Grafana: container not running"
        fi
        
        # Test Java app
        local java_status=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/metrics 2>/dev/null || echo "000")
        if [[ "$java_status" == "200" ]]; then
            echo "  ✅ Java app: http://localhost:8080/metrics (healthy)"
        elif [[ "$java_status" == "000" ]]; then
            echo "  ❌ Java app: http://localhost:8080/metrics (not running)"
            echo "     Start with: ./gradlew run"
        else
            echo "  ⚠️  Java app: http://localhost:8080/metrics (HTTP $java_status)"
        fi
    fi
    
    echo ""
    
    # Add startup time information
    if $prometheus_running || $grafana_running; then
        echo "⏰ Startup Information:"
        if $prometheus_running; then
            local prom_uptime=$(podman ps --format "{{.Status}}" --filter "name=prometheus" | grep -o "Up [^(]*")
            echo "  📊 Prometheus: $prom_uptime"
        fi
        if $grafana_running; then
            local grafana_uptime=$(podman ps --format "{{.Status}}" --filter "name=grafana" | grep -o "Up [^(]*")
            echo "  📈 Grafana: $grafana_uptime"
        fi
        echo ""
    fi
    
    # Data directories
    echo "💾 Data:"
    if [[ -d "./data/prometheus" ]]; then
        local size=$(du -sh ./data/prometheus 2>/dev/null | cut -f1)
        echo "  📁 Prometheus: ${size:-unknown}"
    fi
    if [[ -d "./data/grafana" ]]; then
        local size=$(du -sh ./data/grafana 2>/dev/null | cut -f1)
        echo "  📁 Grafana: ${size:-unknown}"
    fi
    
    echo ""
    
    # Overall status with startup awareness
    if ! command -v curl > /dev/null 2>&1; then
        echo "🟡 Status: Cannot determine service health (curl not available)"
    else
        local prometheus_healthy=false
        local grafana_healthy=false
        local java_healthy=false
        
        # Check HTTP responses - try both IPv4 and IPv6
        if $prometheus_running; then
            local prom_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9090/-/healthy 2>/dev/null || echo "000")
            if [[ "$prom_code" == "000" ]]; then
                prom_code=$(curl -s -o /dev/null -w "%{http_code}" http://[::1]:9090/-/healthy 2>/dev/null || echo "000")
            fi
            [[ "$prom_code" == "200" ]] && prometheus_healthy=true
        fi
        
        if $grafana_running; then
            local grafana_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health 2>/dev/null || echo "000")
            if [[ "$grafana_code" == "000" ]]; then
                grafana_code=$(curl -s -o /dev/null -w "%{http_code}" http://[::1]:3000/api/health 2>/dev/null || echo "000")
            fi
            [[ "$grafana_code" == "200" ]] && grafana_healthy=true
        fi
        
        local java_code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/metrics 2>/dev/null || echo "000")
        [[ "$java_code" == "200" ]] && java_healthy=true
        
        # Status summary
        if $prometheus_healthy && $grafana_healthy && $java_healthy; then
            echo "🟢 Status: All services healthy and ready for monitoring!"
        elif $prometheus_healthy && $grafana_healthy; then
            echo "🟢 Status: Monitoring stack healthy"
            echo "   Start Java app: ./gradlew run"
        elif $prometheus_running && $grafana_running; then
            echo "⏳ Status: Containers running, services starting up"
            echo "   This is normal - services can take 2-5 minutes to fully start"
            echo "   Check progress: podman logs -f prometheus"
        elif $prometheus_running || $grafana_running; then
            echo "🟡 Status: Monitoring stack partially running"
        else
            echo "🔴 Status: Monitoring stack not running"
            echo "   Run: ./stack.sh setup"
        fi
    fi
}

cleanup_monitoring() {
    echo "🛑 Cleaning up monitoring stack"
    echo "==============================="
    
    # Stop containers
    echo "⏹️  Stopping containers..."
    for container in prometheus grafana; do
        if podman ps --format "{{.Names}}" | grep -E "^${container}$" > /dev/null 2>&1; then
            echo "  Stopping $container..."
            podman stop "$container" > /dev/null 2>&1 || true
        fi
    done
    
    # Remove containers
    echo "🗑️  Removing containers..."
    for container in prometheus grafana; do
        if podman ps -a --format "{{.Names}}" | grep -E "^${container}$" > /dev/null 2>&1; then
            echo "  Removing $container..."
            podman rm "$container" > /dev/null 2>&1 || true
        fi
    done
    
    # Clean up config files
    if [[ -d "./data/grafana-config" ]]; then
        rm -rf "./data/grafana-config"
        echo "  ✅ Grafana config removed"
    fi
    
    # Data cleanup option
    if [[ -d "./data" ]]; then
        echo ""
        echo "💾 Data cleanup:"
        echo "   Your monitoring data is in ./data/"
        echo "   This includes metrics history and Grafana dashboards"
        echo ""
        read -p "   Delete data? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🗑️  Removing data..."
            rm -rf ./data
            echo "  ✅ Data removed"
        else
            echo "  ℹ️  Data kept in ./data/"
        fi
    fi
    
    echo ""
    echo "✅ Cleanup complete!"
    echo ""
    echo "🔄 To start fresh: ./stack.sh setup"
}

# Command handling
case "${1:-help}" in
    "setup")
        setup_monitoring
        ;;
    "status")
        show_status
        ;;
    "cleanup")
        cleanup_monitoring
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac