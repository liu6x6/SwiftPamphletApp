# SwiftData 中的模型关系 (@Relationship)

在复杂的应用中，数据模型通常不是孤立存在的。它们之间存在联系，比如“一个用户有多篇文章”（一对多），“一个作者属于多个标签”（多对多）。SwiftData 会自动尝试推断模型之间的关系，但为了更精确的控制，我们需要使用 `@Relationship` 宏。

## 1. 自动推断关系

当你在两个 `@Model` 类中互相引用对方时，SwiftData 默认能够推断出它们的关系。

```swift
@Model
class Department {
    var name: String
    // SwiftData 看到这里有个 Employee 数组，且 Employee 里有 Department
    // 就会自动在底层建立一对多关系
    var employees: [Employee] 

    init(name: String, employees: [Employee] = []) {
        self.name = name
        self.employees = employees
    }
}

@Model
class Employee {
    var name: String
    var department: Department? // 反向引用

    init(name: String, department: Department? = nil) {
        self.name = name
        self.department = department
    }
}
```

## 2. 使用 @Relationship 明确关系与删除规则

如果你需要自定义当关系中的一方被删除时，另一方该如何处理（这在 Core Data 中称为“删除规则” Delete Rule），你就必须显式使用 `@Relationship` 宏。

```swift
@Model
class Author {
    var name: String
    
    // 配置关系：
    // deleteRule: .cascade 表示当这个 Author 被删除时，他名下的所有 Book 也会被自动级联删除！
    // inverse: 明确指明对端模型中的哪个属性是反向指向我的（避免同一实体中有多个同类型属性时发生混淆）
    @Relationship(deleteRule: .cascade, inverse: \Book.author)
    var books: [Book]
    
    init(name: String, books: [Book] = []) {
        self.name = name
        self.books = books
    }
}

@Model
class Book {
    var title: String
    var author: Author?
    
    init(title: String, author: Author? = nil) {
        self.title = title
        self.author = author
    }
}
```

### DeleteRule 删除规则选项

*   `.nullify` (默认值): 当父对象（例如 Author）被删除时，子对象（例如 Book）不会被删除。但 Book 中的 `author` 属性会被置为 `nil`（即斩断联系）。
*   `.cascade`: 级联删除。父对象被删时，所有与之关联的子对象都会被一起从数据库中删除。这适用于强依赖关系，比如删除了一篇文章，它的所有评论也应该消失。
*   `.deny`: 阻止删除。如果该父对象还关联着至少一个子对象，那么**不允许**删除这个父对象。你必须先手动删除或移除所有相关的子对象，才能删除它。

## 3. 多对多关系 (Many-to-Many)

在 SwiftData 中建立多对多关系非常简单，直接让双方都持有对方的数组即可，无需像手写 SQL 那样去创建一张中间的“联结表”（Join Table），SwiftData 会在底层 SQLite 中自动替你完成这一工作。

```swift
@Model
class Student {
    var name: String
    var classes: [SchoolClass] // 一个学生上多门课
    
    init(name: String, classes: [SchoolClass] = []) {
        self.name = name
        self.classes = classes
    }
}

@Model
class SchoolClass {
    var className: String
    // 显式指定反向关系，建立双向多对多
    @Relationship(inverse: \Student.classes)
    var students: [Student] // 一门课有多个学生
    
    init(className: String, students: [Student] = []) {
        self.className = className
        self.students = students
    }
}
```

## 4. 建立关系时的最佳实践

当你试图在代码中把两个对象连接起来时：

```swift
let newStudent = Student(name: "小明")
let newClass = SchoolClass(className: "计算机科学")

// 只需要在一个方向上添加关系，SwiftData 的底层会自动维护双向引用的同步！
// 也就是说，如果你向 newClass 的 students 里加了 newStudent，
// newStudent 的 classes 数组也会在下一次被访问时自动包含 newClass。
newClass.students.append(newStudent)

// 注意：最好确保这两者已经被 context 管理后再建立复杂关系，或者将父节点 insert 后再建关系。
context.insert(newStudent)
context.insert(newClass)
```

**避免循环引用导致的无限递归**：在自定义 `init` 中处理关系属性时要注意，如果两个对象在 `init` 中互相要求对方作为非可选值传入，就会形成死锁。这就是为什么在多对一或多对多关系中，关系属性通常设置为 Optional（`?`）或是空数组（`[]`）并作为可选参数传入。