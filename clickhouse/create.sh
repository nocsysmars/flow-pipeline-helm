#!/bin/bash

cp /tmp/flow.proto /var/lib/clickhouse/format_schemas/flow.proto

set -e

clickhouse client -n <<-EOSQL
    CREATE TABLE IF NOT EXISTS flows
    (
        TimeReceived UInt64,
        TimeFlowStart UInt64,
        SequenceNum UInt32,
        SamplingRate UInt64,
        SamplerAddress FixedString(16),
        SrcAddr FixedString(16),
        DstAddr FixedString(16),
        SrcAS UInt32,
        DstAS UInt32,
        EType UInt32,
        Proto UInt32,
        SrcPort UInt32,
        DstPort UInt32,
        InIf UInt32,
        Bytes UInt64,
        Packets UInt64
    ) ENGINE = Kafka()
    SETTINGS
        kafka_broker_list = '{{.Release.Name}}-kafka.{{.Release.Namespace}}.svc.cluster.local:9092',
        kafka_topic_list = 'flows',
        kafka_group_name = 'clickhouse',
        kafka_format = 'Protobuf',
        kafka_schema = 'flow.proto:FlowMessage';
    CREATE TABLE IF NOT EXISTS flows_raw
    (
        Date Date,
        TimeReceived DateTime,
        TimeFlowStart DateTime,
        SequenceNum UInt32,
        SamplingRate UInt64,
        SamplerAddress FixedString(16),
        SrcAddr FixedString(16),
        DstAddr FixedString(16),
        SrcAS UInt32,
        DstAS UInt32,
        EType UInt32,
        Proto UInt32,
        SrcPort UInt32,
        DstPort UInt32,
        InIf UInt32,
        Bytes UInt64,
        Packets UInt64
    ) ENGINE = MergeTree()
    PARTITION BY Date
    ORDER BY TimeReceived;
    CREATE MATERIALIZED VIEW IF NOT EXISTS flows_raw_view TO flows_raw
    AS SELECT
        toDate(TimeReceived) AS Date,
        *
       FROM flows;
    CREATE TABLE IF NOT EXISTS flows_5m
    (
        Date Date,
        Timeslot DateTime,
        SamplerAddress FixedString(16),
        InIf UInt32,
        -- SrcAS UInt32,
        -- DstAS UInt32,
        ETypeMap Nested (
            EType UInt32,
            Bytes UInt64,
            Packets UInt64,
            Count UInt64
        ),
        Bytes UInt64,
        Packets UInt64,
        Count UInt64
    ) ENGINE = SummingMergeTree()
    PARTITION BY Date
    ORDER BY (Date, Timeslot, SamplerAddress, InIf, \`ETypeMap.EType\`);
    CREATE MATERIALIZED VIEW IF NOT EXISTS flows_5m_view TO flows_5m
    AS
        SELECT
            Date,
            toStartOfFiveMinute(TimeReceived) AS Timeslot,
            SamplerAddress,
            InIf,
            [EType] AS \`ETypeMap.EType\`,
            [Bytes] AS \`ETypeMap.Bytes\`,
            [Packets] AS \`ETypeMap.Packets\`,
            [Count] AS \`ETypeMap.Count\`,
            sum(Bytes) AS Bytes,
            sum(Packets) AS Packets,
            count() AS Count
        FROM flows_raw
        GROUP BY Date, Timeslot, SamplerAddress, InIf, \`ETypeMap.EType\`;
EOSQL
