// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_detail.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrderDetailAdapter extends TypeAdapter<OrderDetail> {
  @override
  final int typeId = 0;

  @override
  OrderDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderDetail(
      orderId: fields[0] as String,
      razorpayOrderId: fields[1] as String?,
      amount: fields[2] as int,
      currency: fields[3] as String,
      status: fields[4] as String,
      paymentId: fields[5] as String?,
      signature: fields[6] as String?,
      createdAt: fields[7] as int,
      updatedAt: fields[8] as int,
      isSynced: fields[9] as bool,
      customerName: fields[10] as String?,
      customerEmail: fields[11] as String?,
      customerPhone: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderDetail obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.orderId)
      ..writeByte(1)
      ..write(obj.razorpayOrderId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.paymentId)
      ..writeByte(6)
      ..write(obj.signature)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.customerName)
      ..writeByte(11)
      ..write(obj.customerEmail)
      ..writeByte(12)
      ..write(obj.customerPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
