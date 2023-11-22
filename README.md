# Cell

⚠️ Cell is not yet ready to use, It still mostly a concept at this stage, look below for more information about what currently works and what does not. Moreover, we are keeping an up-to-date example in the `example` folder, so if you want to see how to use Cell, please check it out.

## 🛠️ Testing and Development:

Currently, Cell cannot be used in a real production environment, since it is not on pub.dev. The best way to test Cell is to clone the repository and run the example project.

## A Minimalistic and Easy-to-Use local Backend for your projects.

**Cell** is a streamlined, pure dart backend database designed exclusively for Dart and Flutter applications. If you are looking for a simple and transparent way to persist data in your application, Cell offers a nimble alternative to traditional databases, that is both easy to use and cross-platform compatible.

## Driving Principles:

- **Pure Dart**: Cell is built entirely in Dart, with no native or platform-specific code, making it perfect for projects aiming at a clean Dart codebase. It also means that Cell is compatible with all platforms supported by Dart, including Flutter, Desktop, and even the command line. We believe that with a pure-dart solution, we can make Cell easy to test, debug and maintain, even if it comes at the cost of some performance.

- **Ease of Use**: With Cell's streamlined and clear API, you can get up and running with minimal setup. Cell is designed to require as little boilerplate code as possible. It also means that Cell is easy to learn and to use, even for beginners.

- **Fast but not Furious**: Cell is designed with developer experience in mind, but with a particular eye to performance. For this reason, it might not compete with the speed of the more established databases, such as ObjectBox and Isar (an awesome solution from which this package takes inspiration). However, we believe that Cell's performance is enough for its scope, and we are working hard to make it even faster.

## Development Roadmap:

We decided to divide the development journey for Cell into four main phases:

- **Core implementations**: In this phase, we will focus on implementing the core features of Cell, such as the data structure, the code generator, and the basic CRUD operations. This phase will be completed with the release of the first stable version of Cell, which will be released as soon as possible. At this stage, Cell will be safe to use in most conditions, but will not be the most resilient solution. At the end of this phase, we want the API to be consolidated and stable, so that we can focus on the next phases without having to worry about breaking changes. Still, small quality of life improvements are possible.
- **Transactions and Queries**: To make Cell a more robust solution, we will implement transactions and queries. This will allow for peace of mind when using Cell in production. This phase will be completed with the release of the second stable version of Cell. We still need to lay the foundation for this phase and believe we could use some help. We opened an [issue](https://github.com/FabrizioG202/cell/issues/1) on the topic, so if you are interested, please check it out.
- **Encryption**: To make Cell a more secure solution, we will implement encryption. As for the previous phase, we still need to lay the foundations and flesh out the details. We opened an [issue](https://github.com/FabrizioG202/cell/issues/2) on the topic, so if you are interested or believe you could help, please check it out.
- **Beyond Transparency**: To make Cell a more transparent solution, we will implement a data inspector. This will allow you to inspect the data stored in your tables, without having to open the files manually. We believe the solution implemented by [Isar](https://github.com/isar/isar/tree/main/packages/isar_inspector) is a great example of what we want to achieve.

### Non-Goals:

To maintain the focus and integrity of Cell's core principles, some features will not be implemented:

- ⚠️ **Relations between tables**. Cell is not intended to be a relational database. If you need to store relational data, you can do so by embedding the data in your models. However, we are open to suggestions on how to implement this feature in a way that is consistent with Cell's core principles.

- ⚠️ **Complex/Explicit Querying**. While basic querying will be implemented, expect limitations. Cell encourages the use of direct Dart code for the manipulation of data.

## Phase 1: Core Implementations

We are currently in the first phase of development for Cell, meaning the package is not yet ready for production. These are the features we want to implement:

- [x] **Code Generation Scaffold**: Basic code generation infrastructure is currently in place.
- [ ] **Basic CRUD Operations**: Basic CRUD support is currently being implemented. The database is however void of any capabilities at the moment.

# Supported Types

- [x] `String`: Encoded as Utf8.
- [x] `double`: Supported and encoded as a float64 (default) or float32. We are working on custom encoding for float16 and float128. If you can help us with this, please open an issue.
- [x] `int`: Supported and encoded as an int32 (default), int8, int16, int64 (⚠️ decodes to a `BigInt`), uint8, uint16, uint32, uint64 and varUint.
- [x] `bool`: Supported and encoded as a single byte (either 0 or 1).
- [x] `DateTime`: Supported and encoded as a `DateTime` with precision up to the millisecond (default) and microsecond.
- [x] `Uint8List`, `ByteData`: Supported and encoded as a list of bytes.
- [x] `List`/`Set`: Supported for any supported type (such as `List<int>`, `List<String>`, ...).
- [x] `enum`: Supported and encoded as a `varuint`.
- [ ] `Map`: Not supported yet.
- [ ] `Duration`: Not supported yet.
- [ ] `BigInt`: Not supported yet.
- [ ] `Uri`: Not supported yet.

# Example Usage / Target API:

Here's an example of how to use the package:

First, we define a `Person` class. This class is annotated with `@Embedded()`, indicating that it's a model that will be stored in the database. Each field in the class is annotated with `@Field(index: x)`, where `x` is a unique index number for each field. The `@EmbeddedConstructor()` annotation is used to annotate the constructor that cell will use to deserialize the class. If the index is not provided, such as in the case of the `metadata` field, the index will be automatically assigned based on a hashing of the field's name. There is no `@ignore` annotation, as the `@Field` annotation explicitly indicates which fields should be managed by Cell, so for example, in the case of the address field, we can simply omit the annotation. And it won't be managed by Cell.

```dart
@Embedded()
final class Person extends Equatable {
  @EmbeddedConstructor()
  Person({
    required this.name,
    this.metadata,
    this.address,
    this.hobbies,
    this.age,
  });

  @Field(index: 0)
  final String name;

  @Field(index: 1, mode: EncodeMode.uint16)
  final int? age;

  // Ignore this field
  String? address;

  @Field(index: 3)
  final List<Hobby>? hobbies;

  @Field()
  final PersonMetadata? metadata;
}
```

For enums, it works very similarly. To maintain API consistency, not annotating a field in an enum will make it so that such field will not be serialized by cell. So, trying to serialize a field with value`Hobby.singing` will result in an error. In the same way, if the annotation is removed from a field which was previously annotated, deserializing it will result in an error.

```dart
@Embedded()
enum Hobby {
  @Field(index: 0)
  reading,

  @Field(index: 1)
  writing,

  @Field(index: 2)
  coding,

  // This will not be supported.
  // Encoding / Decoding will fail.
  singing,
}
```

# FAQs / Implementation details:

- **Why is it called "Cell"?**: We believe the name 'Cell' encapsulates the philosophy of simplicity and minimalism that we want to achieve with this package. It was also (to our knowledge) not already taken by any other package of similar scope.
- **Why do I need to add a `@Field` annotation to my fields?** Because Cell is built with minimalism in mind, we decided to require explicit intent for operations. Through the `@Field` annotation, you clearly designate which fields 'Cell' should manage. This explicitness eliminates the need for guessing on the part of the framework and removes the necessity for a `@ignore` annotation, thereby streamlining the codebase.
- **What is the `@EmbeddedConstructor` annotation for?** This annotation explicitly directs 'Cell' to generate a constructor for the annotated class. This allows a great deal of flexibility, enabling fully custom serialization. More details on this point will be provided in the documentation int the Future.
